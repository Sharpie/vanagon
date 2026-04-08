require 'sbom'
require 'vanagon/extensions/sbom/cyclonedx_generator'

using Vanagon::Extensions::CyclonedxCpe

describe Sbom::Generator do
  let(:generator) { Sbom::Generator.new(sbom_type: :cyclonedx) }

  let(:sbom_data) do
    {
      packages: [package]
    }
  end

  describe 'CyclonedxCpe refinement' do
    context 'when a component has a CPE' do
      let(:package) do
        pkg = Sbom::Data::Package.new
        pkg.name = 'test-component'
        pkg.version = '1.0.0'
        pkg.set_cpe('cpe:2.3:a:vendor:test-component:1.0.0:*:*:*:*:*:*:*')
        pkg.to_h
      end

      it 'extracts the CPE into a top-level cpe key' do
        generator.generate('test-project', sbom_data)
        component = generator.to_h['components'].first
        expect(component['cpe']).to eq('cpe:2.3:a:vendor:test-component:1.0.0:*:*:*:*:*:*:*')
      end

      it 'removes the CPE from externalReferences' do
        generator.generate('test-project', sbom_data)
        component = generator.to_h['components'].first
        expect(component).not_to have_key('externalReferences')
      end
    end

    context 'when a component has a CPE and other external references' do
      let(:package) do
        pkg = Sbom::Data::Package.new
        pkg.name = 'test-component'
        pkg.version = '1.0.0'
        pkg.set_cpe('cpe:2.3:a:vendor:test-component:1.0.0:*:*:*:*:*:*:*')
        pkg.add_external_reference('OTHER', 'website', 'https://example.com')
        pkg.to_h
      end

      it 'keeps non-CPE external references' do
        generator.generate('test-project', sbom_data)
        component = generator.to_h['components'].first
        expect(component['externalReferences']).to eq([{ 'type' => 'website', 'url' => 'https://example.com' }])
      end
    end

    context 'when a component has no CPE' do
      let(:package) do
        pkg = Sbom::Data::Package.new
        pkg.name = 'test-component'
        pkg.version = '1.0.0'
        pkg.to_h
      end

      it 'does not add a cpe key' do
        generator.generate('test-project', sbom_data)
        component = generator.to_h['components'].first
        expect(component).not_to have_key('cpe')
      end
    end
  end
end
