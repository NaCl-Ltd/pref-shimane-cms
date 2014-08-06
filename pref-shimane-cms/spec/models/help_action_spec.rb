require 'spec_helper'

describe HelpAction do
  describe "メソッド" do
    describe "help_check" do
      context "引数で渡したaction,controllerに該当するCmsActionが無い場合" do
        before do
          CmsAction.stub(:find_by).and_return(nil)
        end

        subject{HelpAction.help_check("index", "example")}

        it "nilを返す" do
          expect(subject).to be_nil
        end
      end

      context "引数で渡したaction,controllerに該当するCmsActionがある場合" do
        before do
          @ca = create(:cms_action)
          CmsAction.stub(:find_by).and_return(@ca)
        end

        context "CmsActionに対応するActionMasterが無い場合" do
          before do
            @ca.stub(:action_master).and_return(nil)
          end

          subject{HelpAction.help_check("index", "example")}

          it "nilを返す" do
            expect(subject).to be_nil
          end
        end

        context "CmsActionに対応するActionMasterがある場合" do
          before do
            @am = create(:action_master)
            @ca.stub(:action_master).and_return(@am)
          end

          context "ActionMasterに対応するHelpActionが無い場合" do
            before do
              HelpAction.stub(:find_by).and_return(nil)
            end

            subject{HelpAction.help_check("index", "example")}

            it "nilを返す" do
              expect(subject).to be_nil
            end
          end

          context "ActionMasterに対応するHelpActionがある場合" do
            before do
              @ha = create(:help_action)
              HelpAction.stub(:find_by).and_return(@ha)
            end

            subject{HelpAction.help_check("index", "example")}

            it "HelpActionレコードのhelp_category_idを返す．" do
              expect(subject).to eq(@ha.help_category_id)
            end
          end
        end
      end
    end
  end
end
