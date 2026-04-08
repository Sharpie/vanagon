require 'vanagon/cli'
require 'vanagon/cli/sbom'
require 'vanagon/driver'

describe Vanagon::CLI::Sbom do
  let(:cli) { described_class.new }

  describe '#parse' do
    it 'parses project name and platforms' do
      options = cli.parse(%w[myproject ubuntu-20.04-amd64])
      expect(options['<project-name>']).to eq('myproject')
      expect(options['<platforms>']).to eq('ubuntu-20.04-amd64')
    end

    it 'accepts the --type option' do
      options = cli.parse(%w[--type spdx myproject platform])
      expect(options['--type']).to eq('spdx')
    end

    it 'accepts the short -t option' do
      options = cli.parse(%w[-t spdx myproject platform])
      expect(options['--type']).to eq('spdx')
    end

    it 'defaults --type to cyclonedx' do
      options = cli.parse(%w[myproject platform])
      expect(options['--type']).to eq('cyclonedx')
    end

    it 'accepts the --format option' do
      options = cli.parse(%w[--format yaml myproject platform])
      expect(options['--format']).to eq('yaml')
    end

    it 'accepts the short -f option' do
      options = cli.parse(%w[-f yaml myproject platform])
      expect(options['--format']).to eq('yaml')
    end

    it 'defaults --format to json' do
      options = cli.parse(%w[myproject platform])
      expect(options['--format']).to eq('json')
    end

    it 'accepts the --engine option' do
      options = cli.parse(%w[--engine local myproject platform])
      expect(options['--engine']).to eq('local')
    end

    it 'accepts the short -e option' do
      options = cli.parse(%w[-e local myproject platform])
      expect(options['--engine']).to eq('local')
    end

    it 'accepts the --configdir option' do
      options = cli.parse(%w[--configdir /tmp/configs myproject platform])
      expect(options['--configdir']).to eq('/tmp/configs')
    end

    it 'accepts the --workdir option' do
      options = cli.parse(%w[--workdir /tmp/work myproject platform])
      expect(options['--workdir']).to eq('/tmp/work')
    end

    it 'exits when given no arguments' do
      expect { cli.parse(%w[]) }.to raise_error(SystemExit)
    end
  end

  describe '#options_translate' do
    it 'translates docopt keys to option symbols' do
      docopt_options = {
        '--verbose' => false,
        '--workdir' => nil,
        '--configdir' => '/configs',
        '--engine' => 'local',
        '--type' => 'spdx',
        '--format' => 'json',
        '<project-name>' => 'myproject',
        '<platforms>' => 'platform1'
      }
      translated = cli.options_translate(docopt_options)
      expect(translated[:verbose]).to eq(false)
      expect(translated[:workdir]).to be_nil
      expect(translated[:configdir]).to eq('/configs')
      expect(translated[:engine]).to eq('local')
      expect(translated[:type]).to eq('spdx')
      expect(translated[:format]).to eq('json')
      expect(translated[:project_name]).to eq('myproject')
      expect(translated[:platforms]).to eq('platform1')
    end
  end

  describe '#run' do
    let(:sbom_data) { double('sbom') }

    let(:project) do
      double('project', sbom: sbom_data)
    end

    let(:driver) { double('driver', project: project) }

    let(:generator) { double('generator') }

    let(:base_options) do
      {
        configdir: "#{Dir.pwd}/configs",
        project_name: 'test-project',
        platforms: 'ubuntu-20.04-amd64',
        type: 'cyclonedx',
        format: 'json'
      }
    end

    before do
      allow(Vanagon::Driver).to receive(:new).and_return(driver)
      allow(::Sbom::Generator).to receive(:new).and_return(generator)
      allow(generator).to receive(:generate)
      allow(generator).to receive(:output).and_return('{"bomFormat":"CycloneDX"}')
    end

    it 'creates a Driver for each project/platform combination' do
      expect(Vanagon::Driver).to receive(:new)
        .with('ubuntu-20.04-amd64', 'test-project', base_options)
        .and_return(driver)
      cli.run(base_options)
    end

    it 'creates an Sbom::Generator with the specified type and format' do
      expect(::Sbom::Generator).to receive(:new)
        .with(sbom_type: :cyclonedx, format: :json)
        .and_return(generator)
      cli.run(base_options)
    end

    it 'passes spdx type when specified' do
      expect(::Sbom::Generator).to receive(:new)
        .with(sbom_type: :spdx, format: :json)
        .and_return(generator)
      cli.run(base_options.merge(type: 'spdx'))
    end

    it 'passes yaml format when specified' do
      expect(::Sbom::Generator).to receive(:new)
        .with(sbom_type: :cyclonedx, format: :yaml)
        .and_return(generator)
      cli.run(base_options.merge(format: 'yaml'))
    end

    it 'passes the project sbom data to the generator' do
      expect(generator).to receive(:generate)
        .with('test-project', sbom_data)
      cli.run(base_options)
    end

    it 'outputs the generated SBOM to stdout' do
      expect { cli.run(base_options) }
        .to output(/\{"bomFormat":"CycloneDX"\}/).to_stdout
    end

    it 'handles multiple platforms' do
      expect(Vanagon::Driver).to receive(:new)
        .with('ubuntu-20.04-amd64', 'test-project', anything)
        .and_return(driver)
      expect(Vanagon::Driver).to receive(:new)
        .with('el-8-x86_64', 'test-project', anything)
        .and_return(driver)
      cli.run(base_options.merge(platforms: 'ubuntu-20.04-amd64,el-8-x86_64'))
    end

    it 'catches RuntimeError and reports failures' do
      allow(Vanagon::Driver).to receive(:new)
        .and_raise(RuntimeError, 'build host not available')
      expect(VanagonLogger).to receive(:info)
        .with('Failed to generate bill of materials for the following:')
      expect(VanagonLogger).to receive(:info)
        .with('test-project, ubuntu-20.04-amd64: build host not available')
      expect(VanagonLogger).to receive(:info)
        .with('Finished generating bill of materials')
      cli.run(base_options)
    end

    it 'logs completion message' do
      expect(VanagonLogger).to receive(:info)
        .with('Finished generating bill of materials')
      cli.run(base_options)
    end
  end

  describe '#get_projects' do
    let(:configdir) { '/tmp/test_configs' }
    let(:options) { { configdir: configdir, project_name: 'myproject' } }

    it 'returns the specified project name' do
      allow(Dir).to receive(:exist?)
        .with("#{configdir}/projects").and_return(true)
      allow(Dir).to receive(:exist?)
        .with("#{configdir}/platforms").and_return(true)
      expect(cli.get_projects(options)).to eq(['myproject'])
    end

    it 'returns all projects when project name is "all"' do
      allow(Dir).to receive(:exist?)
        .with("#{configdir}/projects").and_return(true)
      allow(Dir).to receive(:exist?)
        .with("#{configdir}/platforms").and_return(true)
      allow(Dir).to receive(:children)
        .with("#{configdir}/projects")
        .and_return(['foo.rb', 'bar.rb'])
      expect(cli.get_projects(options.merge(project_name: 'all')))
        .to match_array(%w[foo bar])
    end

    it 'exits when config directories do not exist' do
      allow(Dir).to receive(:exist?).and_return(false)
      expect { cli.get_projects(options) }.to raise_error(SystemExit)
    end
  end

  describe '#get_platforms' do
    it 'returns the specified platforms' do
      options = { platforms: 'ubuntu-20.04-amd64,el-8-x86_64' }
      expect(cli.get_platforms(options))
        .to eq(%w[ubuntu-20.04-amd64 el-8-x86_64])
    end
  end

  describe 'CLI integration via top-level parser' do
    it 'routes the sbom subcommand to Vanagon::CLI::Sbom' do
      subject = Vanagon::CLI.new
      options = subject.parse(%w[sbom test-project ubuntu-20.04-amd64])
      expect(options[:project_name]).to eq('test-project')
      expect(options[:platforms]).to eq('ubuntu-20.04-amd64')
      expect(options[:type]).to eq('cyclonedx')
      expect(options[:format]).to eq('json')
    end
  end
end
