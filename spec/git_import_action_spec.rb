describe Fastlane::Actions::GitImportAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The git_import plugin is working!")

      Fastlane::Actions::GitImportAction.run(nil)
    end
  end
end
