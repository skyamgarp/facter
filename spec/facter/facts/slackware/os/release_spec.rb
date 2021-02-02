# frozen_string_literal: true

describe Facts::Slackware::Os::Release do
  describe '#call_the_resolver' do
    subject(:fact) { Facts::Slackware::Os::Release.new }

    before do
      allow(Facter::Resolvers::SpecificReleaseFile).to receive(:resolve)
        .with(:release, { release_file: '/etc/slackware-version',
                          regex: /Slackware ([0-9.]+)/ })
        .and_return(value)
    end

    context 'when version is retrieved from specific file' do
      let(:value) { /Slackware ([0-9.]+)/.match('Slackware 19.4') }
      let(:release) { { 'full' => '19.4', 'major' => '19', 'minor' => '4' } }

      it 'calls Facter::Resolvers::SpecificReleaseFile with version' do
        fact.call_the_resolver
        expect(Facter::Resolvers::SpecificReleaseFile).to have_received(:resolve)
        receive(:resolve)
          .with(:release, { release_file: '/etc/slackware-version',
                            regex: /Slackware ([0-9.]+)/ })
          .and_return(value)
      end

      it 'returns operating system name fact' do
        expect(fact.call_the_resolver).to be_an_instance_of(Array).and \
          contain_exactly(an_object_having_attributes(name: 'os.release', value: release),
                          an_object_having_attributes(name: 'operatingsystemmajrelease',
                                                      value: release['major'], type: :legacy),
                          an_object_having_attributes(name: 'operatingsystemrelease',
                                                      value: release['full'], type: :legacy))
      end
    end

    context 'when version is retrieved from os-release file' do
      let(:value) { nil }
      let(:os_release) { '19.4' }
      let(:release) { { 'full' => '19.4', 'major' => '19', 'minor' => '4' } }

      before do
        allow(Facter::Resolvers::OsRelease).to receive(:resolve).with(:version_id).and_return(os_release)
      end

      it 'calls Facter::Resolvers::OsRelease with version' do
        fact.call_the_resolver
        expect(Facter::Resolvers::OsRelease).to have_received(:resolve).with(:version_id)
      end

      it 'returns operating system name fact' do
        expect(fact.call_the_resolver).to be_an_instance_of(Array).and \
          contain_exactly(an_object_having_attributes(name: 'os.release', value: release),
                          an_object_having_attributes(name: 'operatingsystemmajrelease',
                                                      value: release['major'], type: :legacy),
                          an_object_having_attributes(name: 'operatingsystemrelease',
                                                      value: release['full'], type: :legacy))
      end

      context 'when release can\'t be received' do
        let(:os_release) { nil }

        it 'returns operating system name fact' do
          expect(fact.call_the_resolver).to be_an_instance_of(Facter::ResolvedFact).and \
            have_attributes(name: 'os.release', value: nil)
        end
      end
    end
  end
end
