require 'spec_helper'

describe ImportPage::Importers::PageImporter do
  subject{ described_class.new(section.id, genre, user.id, html_file) }

  let!(:section) { create(:section) }
  let!(:genre) { create(:genre) }
  let!(:user) { create(:user) }

  let(:store_dir)  { Pathname.new(ImportPage::UploadFile.store_path(section.id)) }
  let(:html_file)  { store_dir.join(html_filename) }
  let(:html_filename) { 'import_page' }

  around do |example|
    old = described_class.visitor_data_root
    described_class.visitor_data_root = ImportPage::Engine.root.join('files/visitor_data_test')
    example.call
    described_class.visitor_data_root = old
  end
  before do
    FileUtils.mkdir_p(File.dirname(html_file))
  end
  after do
    FileUtils.rm_rf ImportPage::Engine.root.join('files/visitor_data_test')
    FileUtils.rm_rf(store_dir)
  end

  describe "メソッド" do
    it { should respond_to(:messages) }
    it { should respond_to(:section_id) }
    it { should respond_to(:genre) }
    it { should respond_to(:user_id) }
    it { should respond_to(:path) }

    describe '#import' do
      context '#create_or_update_page で例外が発生する場合' do
        before do
          allow(subject).to receive(:create_or_update_page).and_raise
        end

        it '戻り値は nil であること' do
          expect(subject.import).to be_nil
        end
      end

      context '#ページタイトルに機種依存文字がある場合' do
        let(:html_text) do
          <<-__HTML__.lines.map(&:strip).join("\n")
            <html>
              <head><title>#{html_title}</title></head>
              <body>#{html_body}</body>
            </html>
          __HTML__
        end
        let(:html_title) { '①' }
        let(:html_body)  { 'Html Body' }

        before do
          File.write(html_file, html_text)

          allow_any_instance_of(Susanoo::AccessibilityChecker).to receive(:run)
        end

        it 'ページは取り込まれること' do
          expect do
            subject.import
          end.to change(Page, :count).by(1)
        end

        it 'ページコンテンツは取り込まれること' do
          expect do
            subject.import
          end.to change(PageContent, :count).by(1)
        end

        it '戻り値は取り込んだページのインスタンスであること' do
          page = subject.import
          expect(page).to be_instance_of(Page)
          expect(page).to eq Page.last
        end

        it '戻り値は取り込んだページのタイトルはファイル名であること' do
          page = subject.import
          expect(page.attributes).to include({
            'name' => html_filename,
            'title' => html_filename,
          })
        end

        it '#messages にはページタイトルについてのメッセージがあること' do
          page = subject.import
          anchor = %{<a href="/susanoo/pages/#{page.id}">#{page.name}</a>}
          expect(subject.messages).to match_array([
            I18n.t(:invalid_page_title, scope: subject.class.i18n_message_scope, anchor: anchor),
          ])
        end
      end

      context '#ページ本文に機種依存文字がある場合' do
        let(:html_text) do
          <<-__HTML__.lines.map(&:strip).join("\n")
            <html>
              <head><title>#{html_title}</title></head>
              <body>#{html_body}</body>
            </html>
          __HTML__
        end
        let(:html_title) { 'Html Title' }
        let(:html_body)  { '①' }

        before do
          File.write(html_file, html_text)

          allow_any_instance_of(Susanoo::AccessibilityChecker).to receive(:run)
        end

        it 'ページは取り込まれないこと' do
          expect do
            subject.import
          end.to change(Page, :count).by(0)
        end

        it 'ページコンテンツは取り込まれないこと' do
          expect do
            subject.import
          end.to change(PageContent, :count).by(0)
        end

        it '戻り値は nil であること' do
          expect(subject.import).to be_nil
        end

        it '#messages にはページコンテンツについてのメッセージがあること' do
          subject.import
          pc = PageContent.new
          expect(subject.messages).to match_array([
            pc.errors.full_message(:content, pc.errors.generate_message(:content, :cannot_convert_invalid_chars, chars: CGI.unescapeHTML('&#9312;')))
          ])
        end
      end
    end

    describe '#create_or_update_page' do
      let(:html_text) do
        <<-__HTML__.lines.map(&:strip).join("\n")
          <html>
            <head><title>#{html_title}</title></head>
            <body>#{html_body}</body>
          </html>
        __HTML__
      end
      let(:html_title) { 'Html Title' }
      let(:html_body)  { 'Html Body' }

      before do
        File.write(html_file, html_text)
      end

      context '取り込み対象のページが登録されていない場合' do
        context '適切なファイル名である場合' do
          let(:html_filename) { 'import_page.html' }

          context 'titleタグの内容が適切である場合' do
            let(:html_title) { 'Title' }

            it '取り込まれること' do
              expect do
                subject.send(:create_or_update_page)
              end.to change(Page, :count).by(1)
            end

            it '戻り値は page のインスタンスであること' do
              expect(subject.send(:create_or_update_page)).to be_instance_of(Page)
            end

            it 'Page#name には HTMLファイルのファイル名が設定されていること' do
              expect(subject.send(:create_or_update_page).name).to eq(File.basename(html_filename, '.html'))
            end

            it 'Page#title には title タグの内容が設定されていること' do
              expect(subject.send(:create_or_update_page).title).to eq html_title
            end

            it 'メッセージは追加されないこと' do
              subject.send(:create_or_update_page)
              expect(subject.messages).to have(:no).items
            end
          end

          context 'titleタグの内容が空である場合' do
            let(:html_title) { '' }

            it '取り込まれること' do
              expect do
                subject.send(:create_or_update_page)
              end.to change(Page, :count).by(1)
            end

            it '戻り値は page のインスタンスであること' do
              expect(subject.send(:create_or_update_page)).to be_instance_of(Page)
            end

            it 'Page#name には HTMLファイルのファイル名が設定されていること' do
              expect(subject.send(:create_or_update_page).name).to eq(File.basename(html_filename, '.html'))
            end

            it 'Page#title には HTMLファイルのファイル名が設定されていること' do
              expect(subject.send(:create_or_update_page).title).to eq(File.basename(html_filename, '.html'))
            end

            it 'メッセージは追加されること' do
              subject.send(:create_or_update_page)
              expect(subject.messages).to have(1).items
            end
          end

          context 'titleタグの内容に機種依存文字がある場合' do
            let(:html_title) { '①' }

            it '取り込まれること' do
              expect do
                subject.send(:create_or_update_page)
              end.to change(Page, :count).by(1)
            end

            it '戻り値は page のインスタンスであること' do
              expect(subject.send(:create_or_update_page)).to be_instance_of(Page)
            end

            it 'Page#name には HTMLファイルのファイル名が設定されていること' do
              expect(subject.send(:create_or_update_page).name).to eq(File.basename(html_filename, '.html'))
            end

            it 'Page#title には HTMLファイルのファイル名が設定されていること' do
              expect(subject.send(:create_or_update_page).title).to eq(File.basename(html_filename, '.html'))
            end

            it 'メッセージは追加されること' do
              subject.send(:create_or_update_page)
              expect(subject.messages).to have(1).items
            end
          end
        end

        context '不正なファイル名である場合' do
          let(:html_filename) { '[import.html' }

            it '取り込まれないこと' do
              expect do
                subject.send(:create_or_update_page)
              end.to change(Page, :count).by(0)
            end

          it '戻り値は nil であること' do
            expect(subject.send(:create_or_update_page)).to be_nil
          end

          it 'メッセージは追加されること' do
            subject.send(:create_or_update_page)
            expect(subject.messages).to have(1).items
          end
        end
      end

      context '取り込み対象のページが登録されている場合' do
        let(:html_filename) { "#{page_name}.html" }
        let(:page_name) { 'import_page' }

        let!(:page) { create(:page, name: page_name, title: 'Old', genre: genre) }

        context 'titleタグの内容が適切である場合' do
          let(:html_title) { 'Title' }

          it 'ページの新規登録はされないこと' do
            expect do
              subject.send(:create_or_update_page)
            end.to change(Page, :count).by(0)
          end

          it '戻り値は page の既存の page レコードであること' do
            expect(subject.send(:create_or_update_page)).to eq page
          end

          it 'Page#title には title タグの内容が設定されていること' do
            subject.send(:create_or_update_page)
            expect(page.reload.title).to eq html_title
          end

          it 'メッセージは追加されないこと' do
            subject.send(:create_or_update_page)
            expect(subject.messages).to have(:no).items
          end
        end

        context 'titleタグの内容が空であった場合' do
          let(:html_title) { '' }

          it 'ページの新規登録はされないこと' do
            expect do
              subject.send(:create_or_update_page)
            end.to change(Page, :count).by(0)
          end

          it '戻り値は page の既存の page レコードであること' do
            expect(subject.send(:create_or_update_page)).to eq page
          end

          it 'Page#title は更新されていないこと' do
            subject.send(:create_or_update_page)
            expect(page.reload.title).to eq 'Old'
          end

          it 'メッセージは追加されること' do
            subject.send(:create_or_update_page)
            expect(subject.messages).to have(1).items
          end
        end

        context 'titleタグの内容に機種依存文字がある場合' do
          let(:html_title) { '①' }

          it 'ページの新規登録はされないこと' do
            expect do
              subject.send(:create_or_update_page)
            end.to change(Page, :count).by(0)
          end

          it '戻り値は page の既存の page レコードであること' do
            expect(subject.send(:create_or_update_page)).to eq page
          end

          it 'Page#title は更新されていないこと' do
            subject.send(:create_or_update_page)
            expect(page.reload.title).to eq 'Old'
          end

          it 'メッセージは追加されること' do
            subject.send(:create_or_update_page)
            expect(subject.messages).to have(1).items
          end
        end
      end
    end

    describe '#create_or_update_private_content' do
      let!(:page) { create(:page, genre: genre) }

      let(:html_text) do
        <<-__HTML__.lines.map(&:strip).join("\n")
          <html>
            <head><title>#{html_title}</title></head>
            <body>#{html_body}</body>
          </html>
        __HTML__
      end
      let(:html_title) { 'Html Title' }
      let(:html_body)  { 'Html Body' }

      before do
        # validates_accessibility のスタブ化
        allow(subject).to receive(:validates_accessibility).and_return(true)
        allow(subject).to receive(:import_attached_files)
        File.write(html_file, html_text)
      end

      context 'ページに編集中のコンテンツが無い場合' do
        context '本文に機種依存文字が含まれていない場合' do
          it '新規登録されること' do
            expect do
              subject.send(:create_or_update_private_content, page)
            end.to change(PageContent, :count).by(1)
          end

          it '戻り値は新規登録したページコンテンツであること' do
            expect(
              subject.send(:create_or_update_private_content, page)
            ).to eq PageContent.last
          end

          it '編集中のページコンテンツであること' do
            pc = subject.send(:create_or_update_private_content, page)
            expect(pc.admission).to eq PageContent.page_status[:editing]
          end

          it 'トップニュース掲載は No のページコンテンツであること' do
            pc = subject.send(:create_or_update_private_content, page)
            expect(pc.top_news).to eq PageContent.top_news_status[:no]
          end

          it 'edit_required = true のページコンテンツであること' do
            pc = subject.send(:create_or_update_private_content, page)
            expect(pc.edit_required).to be_true
          end

          it 'PageRevisionが登録登録されること' do
            expect do
              subject.send(:create_or_update_private_content, page)
            end.to change(PageRevision, :count).by(1)
            expect(PageRevision.last.attributes).to include({
              'page_id' => page.id,
              'user_id' => user.id,
            })
          end

          it 'PageContent#normalize_pc! を呼び出していること' do
            expect_any_instance_of(PageContent).to receive(:normalize_pc!)
            subject.send(:create_or_update_private_content, page)
          end

          it 'PageContent#normalize_mobile! を呼び出していること' do
            expect_any_instance_of(PageContent).to receive(:normalize_pc!)
            subject.send(:create_or_update_private_content, page)
          end

          it 'PageContent#plugin_tag_to_erb を呼び出していること' do
            expect_any_instance_of(PageContent).to receive(:plugin_tag_to_erb)
            subject.send(:create_or_update_private_content, page)
          end

          it '#import_attached_files を呼び出していること' do
            pc = page.private_content_or_new
            page.stub(:private_content_or_new).and_return(pc)

            expect(subject).to receive(:import_attached_files).with(pc)
            subject.send(:create_or_update_private_content, page)
          end

          it '#validates_accessibility を呼び出していること' do
            pc = page.private_content_or_new
            page.stub(:private_content_or_new).and_return(pc)

            expect(subject).to receive(:validates_accessibility).with(pc)
            subject.send(:create_or_update_private_content, page)
          end
        end

        context '本文に変換可能な機種依存文字が含まれている場合' do
          let(:html_body)  { '№' }

          it '新規登録されること' do
            expect do
              subject.send(:create_or_update_private_content, page)
            end.to change(PageContent, :count).by(1)
          end

          it '戻り値は新規登録したページコンテンツであること' do
            expect(
              subject.send(:create_or_update_private_content, page)
            ).to eq PageContent.last
          end

          it '編集中のページコンテンツであること' do
            pc = subject.send(:create_or_update_private_content, page)
            expect(pc.admission).to eq PageContent.page_status[:editing]
          end

          it 'トップニュース掲載は No のページコンテンツであること' do
            pc = subject.send(:create_or_update_private_content, page)
            expect(pc.top_news).to eq PageContent.top_news_status[:no]
          end

          it 'edit_required = true のページコンテンツであること' do
            pc = subject.send(:create_or_update_private_content, page)
            expect(pc.edit_required).to be_true
          end

          it 'PageRevisionが登録登録されること' do
            expect do
              subject.send(:create_or_update_private_content, page)
            end.to change(PageRevision, :count).by(1)
            expect(PageRevision.last.attributes).to include({
              'page_id' => page.id,
              'user_id' => user.id,
            })
          end

          it 'PageContent#normalize_pc! を呼び出していること' do
            expect_any_instance_of(PageContent).to receive(:normalize_pc!)
            subject.send(:create_or_update_private_content, page)
          end

          it 'PageContent#normalize_mobile! を呼び出していること' do
            expect_any_instance_of(PageContent).to receive(:normalize_pc!)
            subject.send(:create_or_update_private_content, page)
          end

          it 'PageContent#plugin_tag_to_erb を呼び出していること' do
            expect_any_instance_of(PageContent).to receive(:plugin_tag_to_erb)
            subject.send(:create_or_update_private_content, page)
          end

          it '#import_attached_files を呼び出していること' do
            pc = page.private_content_or_new
            page.stub(:private_content_or_new).and_return(pc)

            expect(subject).to receive(:import_attached_files).with(pc)
            subject.send(:create_or_update_private_content, page)
          end

          it '#validates_accessibility を呼び出していること' do
            pc = page.private_content_or_new
            page.stub(:private_content_or_new).and_return(pc)

            expect(subject).to receive(:validates_accessibility).with(pc)
            subject.send(:create_or_update_private_content, page)
          end
        end

        context '本文に機種依存文字が含まれている場合' do
          let(:html_body)  { '①' }

          it '新規登録されないこと' do
            expect do
              subject.send(:create_or_update_private_content, page)
            end.to change(PageContent, :count).by(0)
          end

          it '戻り値は nil であること' do
            expect(
              subject.send(:create_or_update_private_content, page)
            ).to be_nil
          end

          it 'PageContent で発生したバリデーションエラーがメッセージに追加されること' do
            subject.send(:create_or_update_private_content, page)
            pc = PageContent.new
            expect(subject.messages).to match_array([
              pc.errors.full_message(:content, pc.errors.generate_message(:content, :cannot_convert_invalid_chars, chars: CGI.unescapeHTML('&#9312;')))
            ])
          end

          it 'PageRevisionが登録登録されないこと' do
            expect do
              subject.send(:create_or_update_private_content, page)
            end.to change(PageRevision, :count).by(0)
          end

          it 'PageContent#normalize_pc! は呼び出されないこと' do
            expect_any_instance_of(PageContent).to_not receive(:normalize_pc!)
            subject.send(:create_or_update_private_content, page)
          end
        end
      end

      context 'ページに編集中のコンテンツが有る場合' do
        let!(:page) { create(:page_editing, genre: genre) }
        let(:page_content) { page.private_content }

        context '本文に機種依存文字が含まれていない場合' do
          it 'コンテンツが更新されること' do
            old_body = page_content.content

            expect do
              subject.send(:create_or_update_private_content, page)
            end.to change(PageContent, :count).by(0)
            expect(page.reload.private_content.content).to_not eq old_body
          end

          it '戻り値は更新したページコンテンツであること' do
            old_page_content = page_content

            expect(
              subject.send(:create_or_update_private_content, page)
            ).to eq old_page_content.reload
          end

          it '編集中のページコンテンツであること' do
            pc = subject.send(:create_or_update_private_content, page)
            expect(pc.admission).to eq PageContent.page_status[:editing]
          end

          it 'トップニュース掲載は No のページコンテンツであること' do
            pc = subject.send(:create_or_update_private_content, page)
            expect(pc.top_news).to eq PageContent.top_news_status[:no]
          end

          it 'edit_required = true のページコンテンツであること' do
            pc = subject.send(:create_or_update_private_content, page)
            expect(pc.edit_required).to be_true
          end

          it 'PageContent#normalize_pc! を呼び出していること' do
            expect_any_instance_of(PageContent).to receive(:normalize_pc!)
            subject.send(:create_or_update_private_content, page)
          end

          it 'PageContent#normalize_mobile! を呼び出していること' do
            expect_any_instance_of(PageContent).to receive(:normalize_pc!)
            subject.send(:create_or_update_private_content, page)
          end

          it 'PageContent#plugin_tag_to_erb を呼び出していること' do
            expect_any_instance_of(PageContent).to receive(:plugin_tag_to_erb)
            subject.send(:create_or_update_private_content, page)
          end

          it '#import_attached_files を呼び出していること' do
            pc = page.private_content_or_new
            page.stub(:private_content_or_new).and_return(pc)

            expect(subject).to receive(:import_attached_files).with(pc)
            subject.send(:create_or_update_private_content, page)
          end

          it '#validates_accessibility を呼び出していること' do
            pc = page.private_content_or_new
            page.stub(:private_content_or_new).and_return(pc)

            expect(subject).to receive(:validates_accessibility).with(pc)
            subject.send(:create_or_update_private_content, page)
          end
        end

        context '本文に変換可能な機種依存文字が含まれている場合' do
          let(:html_body)  { '№' }

          it 'コンテンツが更新されること' do
            old_body = page_content.content

            expect do
              subject.send(:create_or_update_private_content, page)
            end.to change(PageContent, :count).by(0)
            expect(page.reload.private_content.content).to_not eq old_body
          end

          it '戻り値は更新したページコンテンツであること' do
            old_page_content = page_content

            expect(
              subject.send(:create_or_update_private_content, page)
            ).to eq old_page_content.reload
          end

          it '編集中のページコンテンツであること' do
            pc = subject.send(:create_or_update_private_content, page)
            expect(pc.admission).to eq PageContent.page_status[:editing]
          end

          it 'トップニュース掲載は No のページコンテンツであること' do
            pc = subject.send(:create_or_update_private_content, page)
            expect(pc.top_news).to eq PageContent.top_news_status[:no]
          end

          it 'edit_required = true のページコンテンツであること' do
            pc = subject.send(:create_or_update_private_content, page)
            expect(pc.edit_required).to be_true
          end

          it 'PageContent#normalize_pc! を呼び出していること' do
            expect_any_instance_of(PageContent).to receive(:normalize_pc!)
            subject.send(:create_or_update_private_content, page)
          end

          it 'PageContent#normalize_mobile! を呼び出していること' do
            expect_any_instance_of(PageContent).to receive(:normalize_pc!)
            subject.send(:create_or_update_private_content, page)
          end

          it 'PageContent#plugin_tag_to_erb を呼び出していること' do
            expect_any_instance_of(PageContent).to receive(:plugin_tag_to_erb)
            subject.send(:create_or_update_private_content, page)
          end

          it '#import_attached_files を呼び出していること' do
            pc = page.private_content_or_new
            page.stub(:private_content_or_new).and_return(pc)

            expect(subject).to receive(:import_attached_files).with(pc)
            subject.send(:create_or_update_private_content, page)
          end

          it '#validates_accessibility を呼び出していること' do
            pc = page.private_content_or_new
            page.stub(:private_content_or_new).and_return(pc)

            expect(subject).to receive(:validates_accessibility).with(pc)
            subject.send(:create_or_update_private_content, page)
          end
        end

        context '本文に機種依存文字が含まれている場合' do
          let(:html_body)  { '①' }

          it 'コンテンツが更新されないこと' do
            old_body = page_content.content

            expect do
              subject.send(:create_or_update_private_content, page)
            end.to change(PageContent, :count).by(0)
            expect(page.reload.private_content.content).to eq old_body
          end

          it '戻り値は nil であること' do
            expect(
              subject.send(:create_or_update_private_content, page)
            ).to be_nil
          end

          it 'PageContent で発生したバリデーションエラーがメッセージに追加されること' do
            subject.send(:create_or_update_private_content, page)
            pc = PageContent.new
            expect(subject.messages).to match_array([
              pc.errors.full_message(:content, pc.errors.generate_message(:content, :cannot_convert_invalid_chars, chars: CGI.unescapeHTML('&#9312;')))
            ])
          end

          it 'PageRevisionが登録登録されないこと' do
            expect do
              subject.send(:create_or_update_private_content, page)
            end.to change(PageRevision, :count).by(0)
          end

          it 'PageContent#normalize_pc! は呼び出されないこと' do
            expect_any_instance_of(PageContent).to_not receive(:normalize_pc!)
            subject.send(:create_or_update_private_content, page)
          end
        end
      end
    end

    describe '#validates_accessibility' do
      let!(:page_content) { create(:page_content) }
      let(:content_body) { '' }

      before do
        page_content.content = content_body
      end

      context '機種依存文字がない場合' do
        let(:content_body) { 'あ' }

        it '戻り値は true であること' do
          expect(subject.send(:validates_platform_dependent_characters, page_content)).to be_true
        end

        it 'メッセージは追加されないこと' do
          subject.send(:validates_platform_dependent_characters, page_content)
          expect(subject.messages).to have(:no).items
        end

        it 'コンテンツは変換されていないこと' do
          subject.send(:validates_platform_dependent_characters, page_content)
          expect(page_content.content).to eq content_body
        end
      end

      context '変換可能な機種依存文字がある場合' do
        let(:content_body) { "\u2116" }  # No.の機種依存文字

        it '戻り値は true であること' do
          expect(subject.send(:validates_platform_dependent_characters, page_content)).to be_true
        end

        it 'メッセージは追加されないこと' do
          subject.send(:validates_platform_dependent_characters, page_content)
          expect(subject.messages).to have(:no).items
        end

        it 'コンテンツには変換された文字が設定されること' do
          subject.send(:validates_platform_dependent_characters, page_content)
          expect(page_content.content).to eq 'No.'
        end
      end

      context '変換不可能な機種依存文字がある場合' do
        let(:content_body) { "\u2460" }  # ①

        it '戻り値は false であること' do
          expect(subject.send(:validates_platform_dependent_characters, page_content)).to be_false
        end

        it 'メッセージは追加されること' do
          subject.send(:validates_platform_dependent_characters, page_content)
          expect(subject.messages).to match_array([
            page_content.errors.full_message(:content, page_content.errors.generate_message(:content, :cannot_convert_invalid_chars, chars: CGI.unescapeHTML('&#9312;')))
          ])
        end

        it 'コンテンツには invalid 設定された数値参照が設定されること' do
          subject.send(:validates_platform_dependent_characters, page_content)
          expect(page_content.content).to eq %{<span class="invalid">&#9312;</span>}
        end
      end

      context '変換できない機種依存文字の数値参照がある場合' do
        let(:content_body) { "&#9312;" }  # ①

        it '戻り値は true であること' do
          expect(subject.send(:validates_platform_dependent_characters, page_content)).to be_true
        end

        it 'メッセージは追加されないこと' do
          subject.send(:validates_platform_dependent_characters, page_content)
          expect(subject.messages).to have(:no).items
        end

        it 'コンテンツは変更されないこと' do
          subject.send(:validates_platform_dependent_characters, page_content)
          expect(page_content.content).to eq '&#9312;'
        end
      end

      context 'ノーブレークスペースがある場合' do
        let(:content_body) { Nokogiri.HTML('&nbsp;').text }

        it '戻り値は true であること' do
          expect(subject.send(:validates_platform_dependent_characters, page_content)).to be_true
        end

        it 'メッセージは追加されないこと' do
          subject.send(:validates_platform_dependent_characters, page_content)
          expect(subject.messages).to have(:no).items
        end

        it 'コンテンツには &nbsp; が設定されること' do
          subject.send(:validates_platform_dependent_characters, page_content)
          expect(page_content.content).to eq '&nbsp;'
        end
      end
    end

    describe '#validates_accessibility' do
      let!(:page_content) { create(:page_content) }

      before do
        allow_any_instance_of(Susanoo::AccessibilityChecker).to receive(:run)
      end

      context 'Susanoo::AccessibilityChecker#run でエラーがない場合' do
        before do
          allow_any_instance_of(Susanoo::AccessibilityChecker).to receive(:errors).and_return([])
        end

        it '戻り値は true であること' do
          expect(
            subject.send(:validates_accessibility, page_content)
          ).to be_true
        end

        it 'メッセージは増えないこと' do
          expect do
            subject.send(:validates_accessibility, page_content)
          end.to change{ subject.messages.size }.by(0)
        end
      end

      context 'Susanoo::AccessibilityChecker#run でエラーがある場合' do
        before do
          allow_any_instance_of(Susanoo::AccessibilityChecker).to receive(:errors).and_return([
            {"id"=>"E_1_3", "args"=>[nil], "tags"=>[{"name"=>"h3", "line"=>242}]},
            {"id"=>"E_2_1", "tags"=>[{"name"=>"img", "line"=>230}, {"name"=>"img", "line"=>230}]},
          ])
        end

        it '戻り値は false であること' do
          expect(
            subject.send(:validates_accessibility, page_content)
          ).to be_false
        end

        it 'エラーはアクセシビリティのエラーだけメッセージは増えること' do
          subject.send(:validates_accessibility, page_content)
          expect(subject.messages).to match_array([
            'E_1_3:' + I18n.t('E_1_3', scope: 'accessibility.errors', default: nil, arg1: nil),
            'E_2_1:' + I18n.t('E_2_1', scope: 'accessibility.errors', default: nil, arg1: nil),
          ])
        end
      end
    end

    describe '#get_html_for_accessibility' do
      let!(:page_content) { create(:page_content, content: 'I Love Ruby!').reload }

      it 'Susanoo::PageContentsController#content の出力と同じであること' do
        allow_any_instance_of(Susanoo::PageContentsController).to receive(:login_required)

        app = ActionDispatch::Integration::Session.new(PrefShimaneCms::Application)
        app.get(app.content_susanoo_page_contents_path(id: page_content.id, page_id: page_content.page_id))
        expect(subject.send(:get_html_for_accessibility, page_content)).to eq app.body
      end
    end

    describe '#import_attached_files' do
      let!(:page_content) { create(:page_content, content: html_body) }
      let(:html_body)  { 'Html Body' }
      let(:data_dir) { Pathname.new(subject.visitor_data_root).join(page_content.page.id.to_s) }

      before do
        FileUtils.rm_rf data_dir
      end

      after do
        FileUtils.rm_rf data_dir
      end

      describe '拡張子による制限制限' do
        describe '添付ファイル全般(画像ファイル含む)' do
          it 'は画面と同じであること' do
            expect(Susanoo::Assets::Base.regex[:attachment_file]).to eq %r{\.(docx?|xlsx?|jaw|jbw|jfw|jsw|jtd|jtt|jtw|juw|jvw|pdf|jpe?g|png|gif|rtf|kml|csv|tsv|txt)\z}i
          end
        end

        describe '画像ファイルのみ' do
          it '画面と同じであること' do
            expect(Susanoo::Assets::Base.regex[:image]).to eq %r{\.(jpe?g|png|gif)\z}i
          end
        end

        context '拡張子以外の場合は' do
          let(:html_body) { %{<a href="#{attached_filename}"></a>} }
          let(:attached_filename) { 'lib.a' }

          it '取り込まれないこと' do
            subject.send(:import_attached_files, page_content)
            expect(page_content.content).to eq html_body
          end
        end
      end

      describe 'タグによる添付ファイルの取り込み制限' do
        context 'html 内に img タグが在る場合' do
          let(:html_body) { %{<img src="#{attached_filename}">} }
          let(:attached_filename) { 'image.png' }

          context 'リンク先のファイルが展開先のフォルダ内に存在する場合' do
            before do
              dir = File.dirname(html_file)
              FileUtils.mkdir_p(dir)
              FileUtils.touch(File.join(dir, attached_filename))
            end

            it 'リンク先のファイルはデータディレクトリにコピーされること' do
              subject.send(:import_attached_files, page_content)
              expect(data_dir.join(attached_filename).exist?).to be_true
            end

            it 'リンクはデータディレクトリの参照する url に置換されること' do
              page = page_content.page
              subject.send(:import_attached_files, page_content)
              expect(page_content.content).to eq(
                %{<img src="#{File.join(page.genre.path, "#{page.name}.data", attached_filename)}">}
              )
            end
          end

          context 'リンク先のファイルが展開先のフォルダ内に存在しない場合' do
            before do
              dir = File.dirname(html_file)
              FileUtils.mkdir_p(dir)
              FileUtils.rm_f(File.join(dir, attached_filename))
            end

            it 'リンク先のファイルはデータディレクトリにコピーされないこと' do
              subject.send(:import_attached_files, page_content)
              expect(data_dir.join(attached_filename).exist?).to be_false
            end

            it 'リンクはデータディレクトリの参照する url に置換されないこと' do
              subject.send(:import_attached_files, page_content)
              expect(page_content.content).to eq html_body
            end
          end

          context 'リンクが http:// から始まる場合' do
            let(:html_body) { %{<img src="http://#{attached_filename}">} }

            before do
              dir = File.dirname(html_file)
              FileUtils.mkdir_p(dir)
              FileUtils.touch(File.join(dir, attached_filename))
            end

            it 'リンク先のファイルはデータディレクトリにコピーされないこと' do
              subject.send(:import_attached_files, page_content)
              expect(data_dir.join(attached_filename).exist?).to be_false
            end

            it 'リンクはデータディレクトリの参照する url に置換されないこと' do
              subject.send(:import_attached_files, page_content)
              expect(page_content.content).to eq html_body
            end
          end
        end

        context 'html 内に a タグが在る場合' do
          let(:html_body) { %{<a href="#{link}">#{attached_filename}</a>} }
          let(:attached_filename) { 'readme.txt' }

          context 'リンク先のファイルが展開先ディレクトリに存在する場合' do
            let(:link) { attached_filename }

            before do
              dir = File.dirname(html_file)
              FileUtils.mkdir_p(dir)
              FileUtils.touch(File.join(dir, attached_filename))
            end

            it 'リンク先のファイルがはデータディレクトリにコピーされること' do
              subject.send(:import_attached_files, page_content)
              expect(data_dir.join(attached_filename).exist?).to be_true
            end

            it 'リンクはデータディレクトリの参照する url に置換されること' do
              page = page_content.page
              subject.send(:import_attached_files, page_content)
              expect(page_content.content).to eq(
                %{<a href="#{File.join(page.genre.path, "#{page.name}.data", attached_filename)}">#{attached_filename}</a>}
              )
            end
          end

          context 'リンク先のファイルが展開先のフォルダ内に存在しない場合' do
            let(:link) { attached_filename }

            before do
              dir = File.dirname(html_file)
              FileUtils.mkdir_p(dir)
              FileUtils.rm_f(File.join(dir, attached_filename))
            end

            it 'リンク先のファイルはデータディレクトリにコピーされないこと' do
              subject.send(:import_attached_files, page_content)
              expect(data_dir.join(attached_filename).exist?).to be_false
            end

            it 'リンクはデータディレクトリの参照する url に置換されないこと' do
              subject.send(:import_attached_files, page_content)
              expect(page_content.content).to eq html_body
            end
          end

          context 'リンクが http:// から始まる場合' do
            let(:link) { %{http://example.com/#{attached_filename}} }

            before do
              dir = File.dirname(html_file)
              FileUtils.mkdir_p(dir)
              FileUtils.touch(File.join(dir, attached_filename))
            end

            it 'リンク先のファイルはデータディレクトリにコピーされないこと' do
              subject.send(:import_attached_files, page_content)
              expect(data_dir.join(attached_filename).exist?).to be_false
            end

            it 'リンクはデータディレクトリの参照する url に置換されないこと' do
              subject.send(:import_attached_files, page_content)
              expect(page_content.content).to eq html_body
            end
          end

          context 'リンクにクエリが含まれる場合' do
            let(:link) { %{#{attached_filename}&amp;a=b} }

            before do
              dir = File.dirname(html_file)
              FileUtils.mkdir_p(dir)
              FileUtils.touch(File.join(dir, attached_filename))
            end

            it 'リンク先のファイルはデータディレクトリにコピーされないこと' do
              subject.send(:import_attached_files, page_content)
              expect(data_dir.join(attached_filename).exist?).to be_false
            end

            it 'リンクはデータディレクトリの参照する url に置換されないこと' do
              subject.send(:import_attached_files, page_content)
              expect(page_content.content).to eq html_body
            end
          end

          context 'リンクにアンカーが含まれる場合' do
            let(:link) { %{#{attached_filename}#h1} }

            before do
              dir = File.dirname(html_file)
              FileUtils.mkdir_p(dir)
              FileUtils.touch(File.join(dir, attached_filename))
            end

            it 'リンク先のファイルはデータディレクトリにコピーされないこと' do
              subject.send(:import_attached_files, page_content)
              expect(data_dir.join(attached_filename).exist?).to be_false
            end

            it 'リンクはデータディレクトリの参照する url に置換されないこと' do
              subject.send(:import_attached_files, page_content)
              expect(page_content.content).to eq html_body
            end
          end
        end
      end

      describe '画像ファイルの取り込み制限' do
        let(:html_body) { %{<img src="#{attached_filename}">} }
#        let(:attached_filename) { 'attached_image.png' }
        let(:attached_filename) { 'attached_image.jpg' }

        before do
          FileUtils.mkdir_p(store_dir)
          FileUtils.cp ImportPage::Engine.root.join("spec/files/#{attached_filename}"), store_dir
        end

        context '画像ファイルのサイズが上限値未満の場合' do
          before do
            Settings[:max_upload_image_size] = File.size(store_dir.join(attached_filename)) + 100.bytes
          end
          after do
            Settings.reload!
          end

          it '取り込まれること' do
            subject.send(:import_attached_files, page_content)
            expect(data_dir.join(attached_filename).exist?).to be_true
          end

          it 'リサイズされていないこと' do
            expected_wxh = %x{identify -format '%wx%h' #{store_dir.join(attached_filename)} 2>/dev/null}.chop
            subject.send(:import_attached_files, page_content)
            actual_wxh = %x{identify -format '%wx%h' #{data_dir.join(attached_filename)} 2>/dev/null}.chop
            expect(actual_wxh).to eq expected_wxh
          end

          it 'メッセージが追加されないこと' do
            subject.send(:import_attached_files, page_content)
            expect(subject.messages).to have(:no).items
          end
        end

        context '画像ファイルのサイズが上限以上の場合' do
          context 'リサイズ後の画像ファイルのサイズが上限未満の場合' do
            before do
              Settings[:max_upload_image_size] = File.size(store_dir.join(attached_filename)) - 10.bytes
            end
            after do
              Settings.reload!
            end

            it '取り込まれること' do
              subject.send(:import_attached_files, page_content)
              expect(data_dir.join(attached_filename).exist?).to be_true
            end

            it 'リサイズされること' do
              expected_wxh = "355x266"  # resize_to_fit でのリサイズ
              subject.send(:import_attached_files, page_content)
              actual_wxh = %x{identify -format '%wx%h' #{data_dir.join(attached_filename)} 2>/dev/null}.chop
              expect(actual_wxh).to eq expected_wxh
            end

            it 'メッセージが追加されないこと' do
              subject.send(:import_attached_files, page_content)
              expect(subject.messages).to have(:no).items
            end
          end

          context 'リサイズ後の画像ファイルのサイズが上限以上の場合' do
            before do
              Settings[:max_upload_image_size] = 10.bytes
            end
            after do
              Settings.reload!
            end

            it '取り込まれないこと' do
              subject.send(:import_attached_files, page_content)
              expect(data_dir.join(attached_filename).exist?).to be_false
            end

            it 'メッセージが追加されないこと' do
              subject.send(:import_attached_files, page_content)
              expect(subject.messages).to have(:no).items
            end
          end
        end

        context '画像ファイルの合計サイズが上限以上の場合' do
          before do
            Settings[:max_upload_image_size] = File.size(store_dir.join(attached_filename)) + 10.bytes
            Settings[:max_upload_image_total_size] = 1.bytes
          end
          after do
            Settings.reload!
          end

          it '例外が発生すること' do
            expect do
              subject.send(:import_attached_files, page_content)
            end.to raise_error(ImportPage::DataInvalid)
          end

          it '取り込まれないこと' do
            subject.send(:import_attached_files, page_content) rescue nil
            expect(data_dir.join(attached_filename).exist?).to be_false
          end

          it 'メッセージが追加されること' do
            subject.send(:import_attached_files, page_content) rescue nil
            expect(subject.messages).to match_array([
              I18n.t(:image_total_size_too_big, scope: subject.class.i18n_message_scope, size: 1),
            ])
          end
        end
      end
    end
  end
end
