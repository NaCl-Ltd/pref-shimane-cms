require 'spec_helper'

describe PageContent do
  describe "バリデーション" do
    it { should validate_presence_of(:page_id) }
    it { should validate_presence_of(:admission) }
  end

  describe "スコープ" do
    describe "eq_publish" do
      subject { PageContent.eq_publish }
      before  { Timecop.freeze(Time.new(2013,4,1)) }
      after   { Timecop.return }

      it "begin_dateがnilの場合、コンテンツを取得できること" do
        content = create(:page_content_publish, begin_date: nil)
        expect(subject).to eq([content])
      end

      it "begin_dateが今日の場合、コンテンツを取得できること" do
        content = create(:page_content_publish, begin_date: Date.today)
        expect(subject).to eq([content])
      end

      it "begin_dateが今日以降の場合、コンテンツを取得できないこと" do
        content = create(:page_content_publish, begin_date: Date.today + 1.days)
        expect(subject.size).to eq(0)
      end

      it "end_dateがnilの場合、コンテンツを取得できること" do
        content = create(:page_content_publish, begin_date: nil, end_date: nil)
        expect(subject).to eq([content])
      end

      it "end_dateが今日の場合、コンテンツを取得できること" do
        content = create(:page_content_publish, begin_date: nil, end_date: Date.today)
        expect(subject).to eq([content])
      end

      it "end_dateが今日以前の場合、コンテンツを取得できないこと" do
        content = create(:page_content_publish, begin_date: nil, end_date: Date.today - 1.days)
        expect(subject.size).to eq(0)
      end

    end

    describe "eq_waiting" do
      subject { PageContent.eq_waiting }
      before  { Timecop.freeze(Time.new(2013,4,1)) }
      after   { Timecop.return }

      it "begin_dateがnilの場合、コンテンツを取得できないこと" do
        content = create(:page_content_publish, begin_date: nil)
        expect(subject.size).to eq(0)
      end

      it "begin_dateが今日の場合、コンテンツを取得できないこと" do
        content = create(:page_content_publish, begin_date: Date.today)
        expect(subject.size).to eq(0)
      end

      it "begin_dateが今日以降の場合、コンテンツを取得できること" do
        content = create(:page_content_publish, begin_date: Date.today + 1.days)
        expect(subject).to eq([content])
      end
    end

    describe "eq_published" do
      subject { PageContent.eq_published }
      before  { Timecop.freeze(Time.new(2013,4,1)) }
      after   { Timecop.return }

      it "begin_dateがnilの場合、公開中または公開停止コンテンツを取得できること" do
        content_1 = create(:page_content_publish, begin_date: nil)
        content_2 = create(:page_content_waiting, begin_date: nil)
        content_3 = create(:page_content_editing, begin_date: nil)
        expect(subject).to eq([content_1, content_2])
      end

      it "begin_dateが今日の場合、コンテンツを取得できること" do
        content = create(:page_content_publish, begin_date: Date.today)
        expect(subject).to eq([content])
      end

      it "begin_dateが今日以降の場合、コンテンツを取得できないこと" do
        content = create(:page_content_publish, begin_date: Date.today + 1.days)
        expect(subject.size).to eq(0)
      end
    end

    describe "eq_private" do
      it "状態が非公開のコンテンツを返す" do
        content_1 = create(:page_content_publish)
        content_2 = create(:page_content_editing)
        content_3 = create(:page_content_request)
        content_4 = create(:page_content_reject)
        expect(PageContent.eq_private).to eq([content_2, content_3, content_4])
      end
    end

    describe "eq_editing" do
      it "編集中のコンテンツを返す" do
        content_1 = create(:page_content_publish)
        content_2 = create(:page_content_editing)
        content_3 = create(:page_content_request)
        content_4 = create(:page_content_reject)
        expect(PageContent.eq_editing).to eq([content_2])
      end
    end

    describe "eq_request" do
      it "公開依頼中のコンテンツを返す" do
        content_1 = create(:page_content_publish)
        content_2 = create(:page_content_editing)
        content_3 = create(:page_content_request)
        content_4 = create(:page_content_reject)
        expect(PageContent.eq_request).to eq([content_3])
      end
    end
  end

  describe "メソッド" do
    describe "#admission_local" do
      before { Timecop.freeze(Time.new(2013,4,1)) }
      after  { Timecop.return }

      shared_examples_for "公開状態別にコード取得" do |label, key|
        before do
          @page_content = create("page_content_#{key}".to_sym)
        end

        it "#{label}のコードが取得できること" do
          expect(@page_content.admission_local).to eq(PageContent.page_status[key])
        end
      end

      it_behaves_like("公開状態別にコード取得", "編集中",  :editing)
      it_behaves_like("公開状態別にコード取得", "公開依頼中", :request)
      it_behaves_like("公開状態別にコード取得", "公開却下", :reject)
      it_behaves_like("公開状態別にコード取得", "公開中", :publish)
      it_behaves_like("公開状態別にコード取得", "公開停止", :cancel)
      it_behaves_like("公開状態別にコード取得", "公開待ち", :waiting)
      it_behaves_like("公開状態別にコード取得", "公開期限切れ", :finished)
    end

    describe "#admission_key" do
      before do
        # 日時を固定
        Timecop.freeze(Time.new(2013,4,1))
      end

      after do
        Timecop.return
      end

      shared_examples_for "公開状態別にキーワード取得" do |label, key|
        before do
          @page_content = create("page_content_#{key}".to_sym)
        end

        it "#{label}のキーワードが取得できること" do
          expect(@page_content.admission_key).to eq(key.to_s)
        end
      end

      it_behaves_like("公開状態別にキーワード取得", "編集中",  :editing)
      it_behaves_like("公開状態別にキーワード取得", "公開依頼中", :request)
      it_behaves_like("公開状態別にキーワード取得", "公開却下", :reject)
      it_behaves_like("公開状態別にキーワード取得", "公開中", :publish)
      it_behaves_like("公開状態別にキーワード取得", "公開停止", :cancel)
      it_behaves_like("公開状態別にキーワード取得", "公開待ち", :waiting)
      it_behaves_like("公開状態別にキーワード取得", "公開期限切れ", :finished)
    end

    describe "#public?" do
      shared_examples_for "非公開コンテンツ判定" do |label, key, result|
        before do
          @page_content = create("page_content_#{key}".to_sym)
        end

        it "#{label}のコンテンツの場合#{result}が返ること" do
          expect(@page_content.public?).to eq(result)
        end
      end

      it_behaves_like("非公開コンテンツ判定", "編集中",  :editing, false)
      it_behaves_like("非公開コンテンツ判定", "公開依頼中", :request, false)
      it_behaves_like("非公開コンテンツ判定", "公開却下", :reject, false)
      it_behaves_like("非公開コンテンツ判定", "公開中", :publish, true)
      it_behaves_like("非公開コンテンツ判定", "公開停止", :cancel, true)
      it_behaves_like("非公開コンテンツ判定", "公開待ち", :waiting, true)
      it_behaves_like("非公開コンテンツ判定", "公開期限切れ", :finished, true)
    end

    describe '#page_status_editable?' do
      context 'edit_required が true の場合' do
        before do
          subject.edit_required = true
        end

        it 'admission = editing では false を返すこと' do
          subject.admission = PageContent.page_status[:editing]
          expect(subject.page_status_editable?).to be_false
        end

        PageContent.page_status.except(:editing).each do |key, value|
          it "admission = #{key} では true を返すこと" do
            subject.admission = value
            expect(subject.page_status_editable?).to be_true
          end
        end
      end

      context 'edit_required が false の場合' do
        before do
          subject.edit_required = false
        end

        it 'admission = editing では true を返すこと' do
          subject.admission = PageContent.page_status[:editing]
          expect(subject.page_status_editable?).to be_true
        end

        PageContent.page_status.except(:editing).each do |key, value|
          it "admission = #{key} では true を返すこと" do
            subject.admission = value
            expect(subject.page_status_editable?).to be_true
          end
        end
      end
    end

    describe "#private?" do
      shared_examples_for "非公開コンテンツ判定" do |label, key, result|
        before do
          @page_content = create("page_content_#{key}".to_sym)
        end

        it "#{label}のコンテンツの場合#{result}が返ること" do
          expect(@page_content.private?).to eq(result)
        end
      end

      it_behaves_like("非公開コンテンツ判定", "編集中",  :editing, true)
      it_behaves_like("非公開コンテンツ判定", "公開依頼中", :request, true)
      it_behaves_like("非公開コンテンツ判定", "公開却下", :reject, true)
      it_behaves_like("非公開コンテンツ判定", "公開中", :publish, false)
      it_behaves_like("非公開コンテンツ判定", "公開停止", :cancel, false)
      it_behaves_like("非公開コンテンツ判定", "公開待ち", :waiting, false)
      it_behaves_like("非公開コンテンツ判定", "公開期限切れ", :finished, false)
    end

    describe "#in_publish?" do
      before do
        @page_content_publish = create(:page_content_publish)
        @page_content_waiting = create(:page_content_waiting)
        @page_content_finished = create(:page_content_finished)
      end

      it "公開中の場合、trueが返ること" do
        expect(@page_content_publish.in_publish?).to be_true
      end

      it "公開待ちの場合、falseが返ること" do
        expect(@page_content_waiting.in_publish?).to be_false
      end

      it "公開期限切れの場合、falseが返ること" do
        expect(@page_content_finished.in_publish?).to be_false
      end
    end

    describe "#publish_started?" do
      before do
        @page_content_publish = create(:page_content_publish)
        @page_content_waiting = create(:page_content_waiting)
      end

      it "公開中の場合、trueが返ること" do
        expect(@page_content_publish.publish_started?).to be_true
      end

      it "公開待ちの場合、falseが返ること" do
        expect(@page_content_waiting.publish_started?).to be_false
      end
    end

    describe "#publish_not_finished?" do
      before do
        @page_content_publish = create(:page_content_publish)
        @page_content_finished = create(:page_content_finished)
      end

      it "公開中の場合、trueが返ること" do
        expect(@page_content_publish.publish_not_finished?).to be_true
      end

      it "公開期限切れの場合、falseが返ること" do
        expect(@page_content_finished.publish_not_finished?).to be_false
      end
    end

    describe "#publish_finished?" do
      before do
        @page_content_publish = create(:page_content_publish)
        @page_content_finished = create(:page_content_finished)
      end

      it "公開中の場合、falseが返ること" do
        expect(@page_content_publish.publish_not_finished?).to be_true
      end

      it "公開期限切れの場合、trueが返ること" do
        expect(@page_content_finished.publish_not_finished?).to be_false
      end
    end

    describe "#section_news_name" do
      shared_examples_for "コード別にキーワード取得" do |label, key|
        before do
          @page_content = create(:page_content_publish,
            section_news: PageContent.section_news_status[key])
        end

        it "#{label}のキーワードが取得できること" do
          expect(@page_content.section_news_name).to eq(key.to_s)
        end
      end

      it_behaves_like("コード別にキーワード取得", "「掲載する」",  :yes)
      it_behaves_like("コード別にキーワード取得", "「掲載しない」", :no)
    end

    describe "#email_with_domain" do
      it "emailがnilでない場合メールアドレスが取得できること" do
        content = create(:page_content_publish, email: "test")
        expect(content.email_with_domain).to eq("#{content.email}@#{Settings.mail.domain}")
      end

      it "emailがnilの場合メールアドレスがnilであること" do
        content = create(:page_content_publish, email: nil)
        expect(content.email_with_domain).to be_nil
      end
    end

    describe "validate_content" do
      let(:page_content){create(:page_content_publish)}
      subject{ page_content.validate_content }

      it "_validate_contentメソッドが呼ばれること" do
        page_content.should_receive(:_validate_content){""}
        subject
      end

      context "_validate_contentメソッドを呼び出すときの検証" do
        it "contentがnilの場合、第一引数にnilを追加して渡すこと" do
          page_content.stub(:content){nil}
          page_content.should_receive(:_validate_content).with('', false){""}
          subject
        end

        it "contentがnil以外の場合、第一引数にself_contentを渡すこと" do
          page_content.stub(:content){"test"}
          page_content.should_receive(:_validate_content).with('test', false){""}
          subject
        end

        it "本メソッドの第一引数にtrueを渡した場合、第２引数にtrueが渡されること" do
          page_content.stub(:content){"test"}
          page_content.should_receive(:_validate_content).with('test', true){""}
          page_content.validate_content(true)
        end
      end

      it "page_contentにエラーがある場合、falseを返すこと" do
        page_content.stub(:_validate_content){""}
        page_content.stub_chain(:errors, :empty?){false}
        expect(subject).to be_false
      end

      it "page_contentにエラーがない場合、trueを返すこと" do
        page_content.stub(:_validate_content){""}
        page_content.stub_chain(:errors, :empty?){true}
        expect(subject).to be_true
      end

      it "機種依存文字が含まれる場合、falseを返すこと" do
        page_content.content = "①+②"
        expect(subject).to be_false
        expect(page_content.errors[:content].any?).to be_true
      end

      it "機種依存文字を変換するオプションを指定した場合、falseを返しcontentの機種依存文字が変換されていること" do
        page_content.content = '㈱会社'
        expect(page_content.validate_content(true)).to be_false
        expect(page_content.errors[:content].any?).to be_true
        expect(page_content.content.to_s).to eq('(株)会社')
      end

      it "変換不能な文字を指定した場合、変換できないこと" do
        page_content.content = '①会社'
        expect(page_content.validate_content(true)).to be_false
        expect(page_content.errors[:content].any?).to be_true
        expect(page_content.content.to_s).to eq("<span class=\"invalid\">&#9312;</span>会社")
      end
    end

    describe "validate_mobile_content" do
      let(:page_content){create(:page_content_publish)}
      subject{page_content.validate_mobile_content}

      it "_validate_contentメソッドが呼ばれること" do
        page_content.should_receive(:_validate_content){""}
        subject
      end

      it "mobileがnilの場合、第一引数にnilを追加して渡すこと" do
        page_content.stub(:mobile){nil}
        page_content.should_receive(:_validate_content).with('', false){""}
        subject
      end

      it "mobileがnil以外の場合、第一引数にself_contentを渡すこと" do
        page_content.stub(:mobile){"test"}
        page_content.should_receive(:_validate_content).with('test', false){""}
        subject
      end

      it "本メソッドの第一引数にtrueを渡した場合、第２引数にtrueが渡されること" do
        page_content.stub(:mobile){"test"}
        page_content.should_receive(:_validate_content).with('test', true){""}
        page_content.validate_mobile_content(true)
      end

      it "page_contentにエラーがある場合、falseを返すこと" do
        page_content.stub(:_validate_content){""}
        page_content.stub_chain(:errors, :empty? ){false}
        expect(subject).to be_false
      end

      it "page_contentにエラーがない場合、trueを返すこと" do
        page_content.stub(:_validate_content){""}
        page_content.stub_chain(:errors, :empty? ){true}
        expect(subject).to be_true
      end
    end

    describe "edit_style_content" do
      let(:c){PageContent.editable_class}
      let(:page_content){create(:page_content_publish)}
      subject{ page_content.edit_style_content }

      it "見出しタグが<div>で囲まれること" do
        page_content.content = "<h1>1</h1>"
        expect_content =  %Q(<div class="#{c[:field]}">\n)
        expect_content += %Q(<div class="#{c[:block]} #{c[:heading]}">\n)
        expect_content += %Q(<h1>1</h1>\n)
        expect_content += %Q(</div>\n)
        expect_content += %Q(</div>)
        expect(subject).to eq(expect_content)
      end

      it "divタグに編集用クラスが追加されること" do
        page_content.format_version = PageContent.current_format_version
        page_content.content = "<div><p>2</p><p>3</p></div>"
        expect_content =  %Q(<div class="#{c[:field]}">\n)
        expect_content += %Q(<div class="#{c[:block]} #{c[:div]}">\n)
        expect_content += %Q(<p>2</p>\n<p>3</p>\n)
        expect_content += %Q(</div>\n)
        expect_content += %Q(</div>)
        expect(subject).to eq(expect_content)
      end
    end

    describe "normalize_pc!" do
      let(:top_genre){ create(:top_genre) }
      let(:genre){ create(:genre, parent_id: top_genre.id ) }
      let(:page) { create(:page, genre_id: genre.id) }
      let(:page_content){create(:page_content_publish, page_id: page.id)}
      subject{ page_content.normalize_pc! }

      describe "normalize_content" do
        it "編集用のHTMLタグ・属性が削除されること" do
          page_content.content = %Q(<div class='editable data-type-h'><h1>1</h1></div><div class='editable data-type-div'><p>2</p></div>)
          subject
          expect(page_content.content.gsub("\n", "")).to eq("<h1>1</h1><div><p>2</p></div>")
        end
      end

      describe "normalize_content_links" do
        it "contentの中のリンクに相対パスが含まれる場合、path+uriに変換されること" do
          content = %Q(<a href="./example/rails.html">test</a>)
          result  = %Q(<a href="#{genre.path}example/rails.html">test</a>)
          page_content.content = content
          expect{subject}.to change{page_content.content}.from(content).to(result)
        end

        it "contentの中のリンクに内部リンクで拡張子が.htmの場合、.htmlに変換されること" do
          content = %Q(<a href="/example/test.htm">test</a>)
          result = %Q(<a href="/example/test.html">test</a>)
          page_content.content = content
          expect{subject}.to change{page_content.content}.from(content).to(result)
        end

        it "contentの中のリンクに内部リンクで/index.htmlが含まれる場合、/に変換されること" do
          content = %Q(<a href="/example/index.html">test</a>)
          result = %Q(<a href="/example/">test</a>)
          page_content.content = content
          expect{subject}.to change{page_content.content}.from(content).to(result)
        end
      end
    end

    describe "normalize_mobile!" do
      let(:page_content){create(:page_content_publish)}
      subject{ page_content.normalize_mobile! }

      it "編集用のHTMLタグ・属性が削除されること" do
        page_content.mobile = %Q(<div class='editable data-type-h'><h1>1</h1></div><div class='editable data-type-div'><p>2</p></div>)
        subject
        expect(page_content.mobile.gsub("\n", "")).to eq("<h1>1</h1><div><p>2</p></div>")
      end
    end

    describe "replace_content_links" do
      let(:top_genre){ create(:top_genre) }
      let(:genre){ create(:genre, parent_id: top_genre.id ) }
      let(:page) { create(:page, genre_id: genre.id) }
      let(:page_content){create(:page_content_publish, page_id: page.id)}
      let(:from){ '/test/from.html' }
      let(:to)  { '/test/to.html' }
      let(:from_other){ '/test/from2.html' }

      subject{page_content.replace_content_links(from, to)}

      it "content内の内部リンクでにfromで渡したリンクが存在する場合、toで渡したリンク先に置換されること" do
        from_content = %Q(<a href="#{from}">test</a>)
        to_content   = %Q(<a href="#{to}">test</a>)
        page_content.content = from_content
        expect{subject}.to change{page_content.content}.from(from_content).to(to_content)
      end

      it "content内の内部リンクでにfromで渡したリンクが存在しない場合、リンクが置換されないこと" do
        from_content = %Q(<a href="#{from_other}">test</a>)
        to_content   = %Q(<a href="#{to}">test</a>)
        page_content.content = from_content
        expect{subject}.to_not  change{page_content.content}
      end
    end

    describe "to_current_format_html" do
      let(:page_content){create(:page_content_publish)}
      let(:c){PageContent.editable_class}

      context 'contentのフォーマットが古い場合' do
        it "見出しタグ以外の要素をdivでブロック分割すること" do
          content = "<h1>1</h1><p>2</p><h2>3</h2><p>4</p>"
          expect_content =  %Q(<div class="#{c[:field]}">)
          expect_content += %Q(<h1>1</h1>)
          expect_content += %Q(<div><p>2</p></div>)
          expect_content += %Q(<h2>3</h2>)
          expect_content += %Q(<div><p>4</p></div>)
          expect_content += "</div>"
          expect(page_content.to_current_format_html(content)).to eq(expect_content)
        end

        it "先頭の見出し以外のタグをdivブロックに含めること" do
          content = "<p>1</p><p>2</p>"
          expect_content =  %Q(<div class="#{c[:field]}">)
          expect_content += %Q(<div><p>1</p><p>2</p></div>)
          expect_content += "</div>"
          expect(page_content.to_current_format_html(content)).to eq(expect_content)
        end

        it "divタグはそのままdivブロックにすること" do
          content = "<div><p>1</p></div><p>2</p>"
          expect_content =  %Q(<div class="#{c[:field]}">)
          expect_content += %Q(<div><p>1</p></div>)
          expect_content += %Q(<div><p>2</p></div>)
          expect_content += "</div>"
          expect(page_content.to_current_format_html(content)).to eq(expect_content)
        end

        it "divタグはそのままdivブロックにし、既存のクラスを消さないこと" do
          content = "<div class='sample'><p>1</p></div><p>2</p>"
          expect_content =  %Q(<div class="#{c[:field]}">)
          expect_content += %Q(<div class="sample"><p>1</p></div>)
          expect_content += %Q(<div><p>2</p></div>)
          expect_content += "</div>"
          expect(page_content.to_current_format_html(content)).to eq(expect_content)
        end

        it "スクリプトブロックが削除されないこと" do
          content = %Q(<%= plugin('page_list')%>)
          expect_content =  %Q(<div class="#{c[:field]}">)
          expect_content += %Q(<%= plugin('page_list') %>)
          expect_content += "</div>"
          expect(page_content.to_current_format_html(content)).to eq(expect_content)
        end

        it "タグで囲まれていない要素をdiv要素に含めること" do
          content = "<p>1</p>\n3\n<br/>4\n<p>5</p>\n"
          expect_content =  %Q(<div class="#{c[:field]}">)
          expect_content += %Q(<div><p>1</p>3<br />4<p>5</p></div>)
          expect_content += "</div>"
          expect(page_content.to_current_format_html(content)).to eq(expect_content)
        end

        it "改行のみの要素を無視すること" do
          content = "<h1>1</h1>\n\n<h2>2</h2>\n \n"
          expect_content =  %Q(<div class="#{c[:field]}">)
          expect_content += %Q(<h1>1</h1>)
          expect_content += %Q(<h2>2</h2>)
          expect_content += "</div>"
          expect(page_content.to_current_format_html(content)).to eq(expect_content)
        end
      end

      context 'contentのフォーマットが新しい場合' do
        it "コンテンツが変換されないこと" do
          content = %Q(<div class="#{c[:field]}"><%= plugin('page_list')%></div>\n)
          expect(page_content.to_current_format_html(content)).to eq(content)
        end

        it "編集用タグを持つ場合も強制的に変換できること" do
          content = %Q(<div class="#{c[:field]}"><p>1</p><p>2</p></div>)
          expect_content =  %Q(<div class="#{c[:field]}">)
          expect_content += %Q(<div><p>1</p><p>2</p></div>)
          expect_content += "</div>"
          expect(page_content.to_current_format_html(content, true)).to eq(expect_content)
        end
      end
    end

    describe "save_with_normalization" do
      let(:c) { PageContent.editable_class }
      let(:user) { create(:user) }
      let(:page_content) {
        create(:page_content_publish,
          content: %Q(<div class="#{c[:field]}"><%= plugin('page_list', '1', '2') %></div>),
          mobile: %Q(<div class="#{c[:field]}"><%= plugin('page_list', '1', '2') %></div>)
        )
      }
      subject{ page_content.save_with_normalization(user) }

      it "trueが返ること" do
        page_content.content = 'xx'
        expect(subject).to be_true
      end

      it "編集用のHTMLタグ・属性が削除されること" do
        page_content.content = %Q(<div class="#{c[:field]}"><div class='editable data-type-h'><h1>1</h1></div><div class='editable data-type-div'><p>2</p></div></div>)
        subject
        expect(page_content.content.gsub("\n", "")).to eq(%Q(<div class="#{c[:field]}"><h1>1</h1><div><p>2</p></div></div>))
      end

      it "編集用のプラグインボタンがスクリプトブロックに変換されること" do
        page_content.content = %Q(<div class="#{c[:field]}"><button class="editable data-type-plugin" name="page_list" value="1,2">#{I18n.t('widgets.items.page_list')}</button></div>)
        subject
        expect(page_content.content.gsub("\n", "")).to eq(%Q(<div class="#{c[:field]}"><%= plugin('page_list', '1', '2') %></div>))
      end

      it "PC用コンテンツのみ変更する場合、携帯用コンテンツが変更されないこと" do
        before_mobile = page_content.mobile
        page_content.content = %Q(<div class="#{c[:field]}"><button class="editable data-type-plugin" name="page_list" value="1,2">#{I18n.t('widgets.items.page_list')}</button></div>)
        subject
        expect(page_content.content.gsub("\n", "")).to eq(%Q(<div class="#{c[:field]}"><%= plugin('page_list', '1', '2') %></div>))
        expect(page_content.mobile).to eq(before_mobile)
      end

      it "携帯用コンテンツのみ変更する場合、PC用コンテンツが変更されないこと" do
        before_content = page_content.content
        page_content.mobile = %Q(<div class="#{c[:field]}"><button class="editable data-type-plugin" name="page_list" value="1,2">#{I18n.t('widgets.items.page_list')}</button></div>)
        subject
        expect(page_content.mobile.gsub("\n", "")).to eq(%Q(<div class="#{c[:field]}"><%= plugin('page_list', '1', '2') %></div>))
        expect(page_content.content).to eq(before_content)
      end

    end

    describe "page_view" do
      let(:page_content){create(:page_content_publish)}
      subject{ page_content.page_view(html: html, is_mobile: is_mobile, plugin_convert: plugin_convert) }

      context "is_mobileがfalseの場合" do
        let(:html) {'<h1>1</h1>' }
        let(:is_mobile){ false }
        let(:plugin_convert){ false }

        before { @page_view = subject }

        it "page_view#mobileがfalseであること" do
          expect(@page_view.mobile).to be_false
        end

        it "PageContent#contentにhtmlの値が設定されていること" do
          expect(page_content.content.gsub("\n", "")).to eq(html)
        end
      end

      context "is_mobileがtrueでない場合" do
        let(:html) {'<h1>1</h1>' }
        let(:is_mobile){ true }
        let(:plugin_convert){ false }

        before { @page_view = subject }

        it "page_view#mobileがtrueであること" do
          expect(@page_view.mobile).to be_true
        end

        it "PageContent#mobileにhtmlの値が設定されていること" do
          expect(page_content.mobile.gsub("\n", "")).to eq(html)
        end
      end

      context "plugin_convertがfalseの場合" do
        let(:html) {%Q(<h1>1</h1><button class="editable data-type-plugin" name="page_list" value="">#{I18n.t('widgets.items.page_list')}</button>) }
        let(:is_mobile){ false }
        let(:plugin_convert){ false }
        before { @page_view = subject }
        it "PageContent#contentが変換されていないこと" do
          expect_html = %Q(<h1>1</h1><button class="editable data-type-plugin" name="page_list" value="">#{I18n.t('widgets.items.page_list')}</button>)
          expect(@page_view.content.gsub("\n", "")).to eq(expect_html)
        end
      end

      context "plugin_convertがtrueの場合" do
        let(:html) {%Q(<h1>1</h1><button class="editable data-type-plugin" name="page_list" value="">#{I18n.t('widgets.items.page_list')}</button>) }
        let(:is_mobile){ false }
        let(:plugin_convert){ true }
        before { @page_view = subject }
        it "PageContent#contentが変換されること" do
          expect_html = %Q(<h1>1</h1>\n<%= plugin('page_list') %>)
          expect(@page_view.content).to eq(expect_html)
        end
      end
    end

    describe "edit_style_page_view" do
      let(:c){PageContent.editable_class}
      let(:page_template) { create(:page_template) }
      let(:page_content) { create(:page_content_publish) }
      subject{ page_content.edit_style_page_view(template_id: template_id, is_mobile: is_mobile, is_copy: is_copy) }

      context "template_idがnilの場合" do
        let(:template_id){ nil }
        let(:is_mobile){ false }
        let(:is_copy){ false }

        it "PageContent#contentが編集用のコンテンツに変換されていること" do
          page_content.content = '<h1>1</h1>'
          to = %Q(<div class="#{c[:field]}"><div class="editable data-type-h"><h1>1</h1></div></div>)
          subject
          expect( page_content.content.gsub("\n", "") ).to eq(to)
        end
      end

      context "template_idがnilでない場合" do
        let(:template_id){ page_template.id }
        let(:is_mobile){ nil }
        let(:is_copy){ nil }

        context "contentがnilでない場合" do
          it "PageContent#contentが編集用のコンテンツに変換されていること" do
            page_content.content = '<h1>1</h1>'
            to = %Q(<div class="#{c[:field]}"><div class="editable data-type-h"><h1>1</h1></div></div>)
            subject
            expect( page_content.content.gsub("\n", "") ).to eq(to)
          end
        end

        context "contentがnilの場合" do
          it "PageTemplate#contentの内容を元に編集用のコンテンツに変換されていること" do
            page_content.content = nil
            from = page_content.content
            to = %Q(<div class="#{c[:field]}"><div class="editable data-type-h"><h1>見出し</h1></div></div>)
            subject
            expect(page_content.content.gsub("\n", "")).to eq(to)
          end
        end
      end

      context "is_mobileがfalseの場合" do
        let(:template_id){ nil }
        let(:is_mobile){ false }
        let(:is_copy){ false }

        it "page_view#mobileがfalseであること" do
          page_view = subject
          expect(page_view.mobile).to be_false
        end
      end

      context "is_mobileがtrueの場合" do
        let(:template_id){ nil }
        let(:is_mobile){ true }
        let(:is_copy){ false }

        before do
          @html = %Q(<h1>1</h1>)
          page_content.mobile = @html
          @page_view = subject
        end

        it "page_view#mobileがtrueであること" do
          expect(@page_view.mobile).to be_true
        end

        it "PageContent#mobileにhtmlの値が設定されていること" do
          expect(page_content.mobile.gsub("\n","")).to eq(%Q(<div class="#{c[:field]}"><div class=\"editable data-type-h\"><h1>1</h1></div></div>))
        end
      end

      context "is_copyがtrueでない場合" do
        let(:template_id){ nil }
        let(:is_mobile){ true }
        let(:is_copy){ true }

        before do
          @html = %Q(<h1>1</h1>)
          page_content.content = @html
          @page_view = subject
        end

        it "page_view#mobileがtrueであること" do
          expect(@page_view.mobile).to be_true
        end

        it "PageContent#mobileにhtmlの値が設定されていること" do
          expect(page_content.mobile.gsub("\n", "")).to eq(%Q(<div class="#{c[:field]}"><div class=\"editable data-type-h\"><h1>1</h1></div></div>))
        end
      end
    end

    describe "#copy_from!" do

    end

    describe "#copy_from!" do
      let(:page_content) { create(:page_content_editing) }
      let(:to_path) { Rails.root.join('files', Rails.env, page_content.page.id.to_s) }
      let(:from_path) { Rails.root.join('files', Rails.env, from_content.page.id.to_s) }

      context "コピー元に画像が含まれていない場合" do
        let(:from_content) { create(:page_content_editing, content: Nokogiri::HTML.parse("コピーされるページコンテント").to_html) }
        subject{ page_content.copy_from!(from_content) }

        it "ファイルを格納するディレクトリが作成されていないこと" do
          subject
          expect(File.exists?(to_path)).to be_false
        end

        it "contentがコピーされていること " do
          subject
          expect(page_content.content).to eq(from_content.content)
        end
      end

      context "コピー元に画像が含まれている場合" do
        let(:from_page) { create(:page) }
        let(:html) {"<img src='#{from_page.url_base_path}.data/rails.png' />" }
        let(:from_content) { create(:page_content_editing, page: from_page, content: Nokogiri::HTML.parse(html).to_html) }
        subject{ page_content.copy_from!(from_content) }

        before do
          FileUtils.mkdir from_path unless File.exists? from_path
          FileUtils.cp File.join(Rails.root, "spec/files/rails.png"), from_path
        end

        it "画像ファイルがコピーされていること" do
          subject
          expect(File.exists?(File.join(to_path, "rails.png"))).to be_true
        end

        it "contentの画像のパスが置換されていること" do
          subject
          expect(Nokogiri::HTML.parse(page_content.content).xpath("//img").first["src"]).to eq("#{page_content.page.url_base_path}.data/rails.png")
        end

        after do
          FileUtils.rm_r from_path if File.exists? from_path
          FileUtils.rm_r to_path if File.exists? to_path
        end
      end

      context "コピー元に画像以外のファイルが含まれている場合" do
        let(:from_page) { create(:page) }
        let(:html) {"<a href='#{from_page.url_base_path}.data/test.txt' />" }
        let(:from_content) { create(:page_content_editing, page: from_page, content: Nokogiri::HTML.parse(html).to_html) }
        subject{ page_content.copy_from!(from_content) }

        before do
          FileUtils.mkdir from_path unless File.exists? from_path
          File.open(File.join(from_path, "test.txt"), "w") { |f| f.print "test" }
        end

        it "ファイルを格納するディレクトリが作成されていないこと" do
          subject
          expect(File.exists?(to_path)).to be_false
        end

        it "contentがコピーされていること " do
          subject
          expect(page_content.content).to eq(from_content.content)
        end

        after do
          FileUtils.rm_r from_path if File.exists? from_path
          FileUtils.rm_r to_path if File.exists? to_path
        end
      end
    end

    describe "private" do
      describe "#publish!" do
        let(:begin_date) { Time.local(2013, 12, 31, 0, 0, 0) }
        let(:end_date) { Time.local(2013, 2, 31, 0, 0, 0) }
        let(:time_now) { Time.local(2013, 1, 31, 0, 0, 0) }
        let(:page) { create(:page) }
        let(:page_content) { create(:page_content_editing, page: page, begin_date: begin_date, end_date: end_date) }

        before do
          Time.stub(:now) { time_now }
        end

        subject{ page_content.send(:publish!) }

        context "ジョブが登録されていない場合" do

          shared_examples_for "ジョブの検証" do
            let(:create_page_job){ Job.where(action: Job::CREATE_PAGE, arg1: @target.id.to_s).first }
            let(:cancel_page_job){ Job.where(action: Job::CANCEL_PAGE, arg1: @target.id.to_s).first }

            it "create_pageジョブのarg1がpage_idであること" do
              subject
              expect(create_page_job.present?).to be_true
            end

            it "begin_dateがある場合、create_pageジョブのdatetime=begin_dateとなる" do
              subject
              expect(create_page_job.datetime.to_i).to eq(begin_date.to_i)
            end

            it "begin_dateがnilの場合、create_pageジョブのdatetime=Time.nowとなる" do
              page_content.begin_date = nil
              subject
              expect(create_page_job.datetime.to_i).to eq(time_now.to_i)
            end

            it "cancel_pageジョブのarg1がpage_idであること" do
              subject
              expect(cancel_page_job.present?).to be_true
            end

            it "cancel_pageジョブのdatetime=end_dateとなる" do
              subject
              expect(cancel_page_job.datetime.to_i).to eq(end_date.to_i)
            end

            it "end_dateがnilの場合、cancel_pageジョブが作成されない" do
              page_content.end_date = nil
              subject
              expect(cancel_page_job).to eq(nil)
            end
          end

          context "コピーページがない場合" do
            before { @target = page }
            it_behaves_like "ジョブの検証"
          end

          context "コピーページがある場合" do
            before { @target = create(:page, original_id: page.id) }
            it_behaves_like "ジョブの検証"
          end
        end

        context "ジョブが登録されている場合" do
          before do
            create(:job, arg1: page.id, action: Job::CANCEL_PAGE, datetime: begin_date+1)
            create(:job, arg1: page.id, action: Job::CANCEL_PAGE, datetime: begin_date-1)
            create(:job, arg1: page.id, action: Job::CANCEL_PAGE, datetime: begin_date)
            create(:job, arg1: page.id, action: Job::CANCEL_PAGE, datetime: time_now+1)
            create(:job, arg1: page.id, action: Job::CANCEL_PAGE, datetime: time_now-1)
            create(:job, arg1: page.id, action: Job::CANCEL_PAGE, datetime: time_now)

            create(:job, arg1: page.id, action: Job::CREATE_PAGE, datetime: time_now-1)
            create(:job, arg1: page.id, action: Job::CREATE_PAGE, datetime: time_now+1)
            create(:job, arg1: page.id, action: Job::CREATE_PAGE, datetime: end_date)
            create(:job, arg1: page.id, action: Job::CREATE_PAGE, datetime: end_date+1)
            create(:job, arg1: page.id, action: Job::CREATE_PAGE, datetime: end_date-1)
          end

          let(:job_scope){Job.where("arg1 = ?", page.id.to_s)}

          context "公開待ちページがない場合" do
            before{page.stub(:waiting_content){ nil }}

            describe "cancel_pageジョブの削除" do
              it "begin_date==nilの場合、datetime>=Time.nowが条件に設定されること" do
                page_content.stub(:begin_date){nil}
                ids = job_scope.where('action = ? AND datetime >= ?', Job::CANCEL_PAGE, time_now).map(&:id)
                subject
                ids.each{|id|expect(Job.exists?(id)).to be_false}
              end

              it "begin_date==nilではない場合、datetime>=begin_dateが条件に設定されること" do
                page_content.stub(:begin_date){begin_date}
                ids = job_scope.where('action = ? AND datetime >= ?', Job::CANCEL_PAGE, begin_date).map(&:id)
                subject
                ids.each{|id|expect(Job.exists?(id)).to be_false}
              end
            end

            describe "create_pageジョブの削除" do
              it "datetime<=Time.nowが条件に設定されること" do
                ids = job_scope.where('action = ? AND datetime <= ?', Job::CREATE_PAGE, time_now).map(&:id)
                subject
                ids.each{|id|expect(Job.exists?(id)).to be_false}
              end
            end
          end

          context "自身が公開待ちページの場合" do
            before{page_content.page.stub(:waiting_content) { page_content } }

            describe "cancel_pageジョブの削除" do
              it "begin_date==nilの場合、datetime>=Time.nowが条件に設定されること" do
                page_content.begin_date = nil
                ids = job_scope.where('action = ? AND datetime >= ?', Job::CANCEL_PAGE, time_now).map(&:id)
                subject
                ids.each{|id|expect(Job.exists?(id)).to be_false}
              end

              it "begin_date==nilではない場合、datetime>=begin_dateが条件に設定されること" do
                ids = job_scope.where('action = ? AND datetime >= ?', Job::CANCEL_PAGE, begin_date).map(&:id)
                subject
                ids.each{|id|expect(Job.exists?(id)).to be_false}
              end
            end

            describe "create_pageジョブの削除" do
              it "datetime<=Time.nowが条件に設定されること" do
                ids = job_scope.where('action = ? AND datetime <= ?', Job::CREATE_PAGE, time_now).map(&:id)
                subject
                ids.each{|id|expect(Job.exists?(id)).to be_false}
              end
            end
          end

          context "自身が公開待ちページでない場合" do
            let(:waiting_content){create(:page_content, begin_date: begin_date+1, end_date: end_date-1)}
            before do
              page.stub(:waiting_content){waiting_content}
            end

            describe "cancel_pageジョブの削除" do
              it "begin_date==nilの場合、datetime>=Time.nowが条件に設定されること" do
                page_content.stub(:begin_date){nil}
                ids = job_scope.where('action = ? AND datetime >= ? AND NOT datetime = ?', Job::CANCEL_PAGE, time_now, waiting_content.end_date).map(&:id)
                subject
                ids.each{|id|expect(Job.exists?(id)).to be_false}
              end

              it "begin_date==nilではない場合、datetime>=begin_dateが条件に設定されること" do
                page_content.stub(:begin_date){begin_date}
                ids = job_scope.where('action = ? AND datetime >= ? AND NOT datetime = ?', Job::CANCEL_PAGE, begin_date, waiting_content.end_date).map(&:id)
                subject
                ids.each{|id|expect(Job.exists?(id)).to be_false}
              end
            end

            describe "create_pageジョブの削除" do
              it "datetime<=Time.nowが条件に設定されること" do
                ids = job_scope.where('action = ? AND datetime <= ? AND NOT datetime = ?', Job::CREATE_PAGE, time_now, waiting_content.begin_date).map(&:id)
                subject
                ids.each{|id|expect(Job.exists?(id)).to be_false}
              end
            end
          end
        end
      end

      describe "#update_remove_attachment_job" do
        let(:page) { create(:page) }
        let(:page_content) { create(:page_content_publish, page: page) }
        let(:path_base) { page.path_base }
        let(:arg1) { page.path_base + ".data/" }
        let(:time_now) { Time.local(2013, 12, 31, 0, 0, 0) }

        subject{ page_content.send(:update_remove_attachment_job) }

        before do
          Time.stub(:now) { time_now }
        end

        context "remove_attachmentジョブが存在する場合" do
          before{create(:job, action: Job::REMOVE_ATTACHMENT, arg1: arg1)}

          context "enable_remove_attachmentジョブが存在する場合" do
            let(:job){create(:job, action: Job::ENABLE_REMOVE_ATTACHMENT, arg1: arg1)}
            before{Job.stub(:find_by){job}}

            it "begin_dateがnilでは無い場合、datetimeにbegin_dateが設定されること" do
              datetime = DateTime.now
              page_content.stub(:begin_date){datetime}
              expect{subject}.to change{job.datetime}.to(datetime)
            end

            it "begin_dateが条件に設定されることnilの場合、Time.nowの値が設定されること" do
              page_content.stub(:begin_date){nil}
              expect{subject}.to change{job.datetime}.to(time_now)
            end
          end

          context "enable_remove_attachmentジョブが存在しない場合" do
            it "action=Job::ENABLE_REMOVE_ATTACHMENTであること" do
              subject
              job = Job.last
              expect(job.action).to eq(Job::ENABLE_REMOVE_ATTACHMENT)
            end

            it "arg1=page.path_base+'.data/'であること" do
              subject
              job = Job.last
              expect(job.arg1).to eq(arg1)
            end

            it "begin_dateがnilでは無い場合、datetimeにbegin_dateが設定されること" do
              datetime = DateTime.now
              page_content.stub(:begin_date){datetime}
              subject
              job = Job.last
              expect(job.datetime.to_i).to eq(datetime.to_i)
            end

            it "begin_dateが条件に設定されることnilの場合、Time.nowの値が設定されること" do
              page_content.stub(:begin_date){nil}
              subject
              job = Job.last
              expect(job.datetime).to eq(time_now)
            end
          end
        end
      end

      describe "#clear_history" do
        let(:page) { create(:page) }

        context "履歴が最大サイズ以内の場合" do
          let(:limit) { Settings.page_content.limit }
          before do
            @page_contents = create_list(:page_content_publish, limit, page: page)
            @page_content = @page_contents.last
          end

          it "page_contentsテーブルからレコードが削除されないこと" do
            expect{ @page_content.send(:clear_history) }.to change(PageContent, :count).by(0)
          end
        end

        context "履歴が最大サイズより大きいの場合" do
          let(:over) { 3 }
          let(:page_link_size) { 3 }
          let(:limit) { Settings.page_content.limit + over }
          before do
            @page_contents = create_list(:page_content_publish, limit, page: page)
            @page_contents.each do |c|
              create_list(:page_link, page_link_size, page_content_id: c.id)
            end
            @delete_page_contents = @page_contents[0, 3]
            @survive_page_contents = @page_contents[3..-1]
            @page_content = @page_contents.last
          end

          it "page_contentsテーブルからレコードが削除されること" do
            expect{ @page_content.send(:clear_history) }.to change(PageContent, :count).by(-1 * over)
            @survive_page_contents.each do |c|
              expect(PageContent.where(id: c.id).present?).to be_true
            end
            @delete_page_contents.each do |c|
              expect(PageContent.where(id: c.id).blank?).to be_true
            end
          end
        end

        context "最新のコンテンツが公開中コンテンツの場合" do
          let(:page_content_size) { 3 }
          let(:page_link_size) { 3 }

          before do
            @page_content_histories = create_list(:page_content_publish, page_content_size, page: page, latest: true).reverse
            @page_content_histories.each do |c|
              create_list(:page_link, page_link_size, page_content_id: c.id)
            end

            @page_content = create(:page_content_publish, page: page)
            create_list(:page_link, page_link_size, page_content_id: @page_content.id)
          end

          it "最新のコンテンツのlatestはtrueであること" do
            @page_content.send(:clear_history)
            expect(@page_content.reload.latest).to be_true
          end

          it "最新のコンテンツのPageLinkが削除されないこと" do
            @page_content.send(:clear_history)
            expect(@page_content.reload.links.size).to eq(page_link_size)
          end

          it "過去のコンテンツのlatestがfalseになること" do
            @page_content.send(:clear_history)
            @page_content_histories.each do |h|
              expect(h.reload.latest).to be_false
            end
          end

          it "過去のコンテンツのPageLinkが削除されること" do
            expect{ @page_content.send(:clear_history) }.to change(PageLink, :count).by(-1 * page_content_size * page_link_size)
            @page_content_histories.each do |h|
              expect(h.reload.links.size).to eq(0)
            end
          end
        end

        context "最新のコンテンツが公開待ちコンテンツの場合" do
          let(:page_content_size) { 3 }
          let(:page_link_size) { 3 }

          before do
            histories = create_list(:page_content_publish, page_content_size, page: page, latest: true).reverse
            histories.each do |c|
              create_list(:page_link, page_link_size, page_content_id: c.id)
            end
            @page_content_histories = histories[1..-1]
            @page_content_just_before = histories.first
            @page_content = create(:page_content_waiting, page: page)
            create_list(:page_link, page_link_size, page_content_id: @page_content.id)
          end

          it "最新のコンテンツのlatestはtrueであること" do
            @page_content.send(:clear_history)
            expect(@page_content.reload.latest).to be_true
          end

          it "最新のコンテンツのPageLinkが削除されないこと" do
            @page_content.send(:clear_history)
            expect(@page_content.reload.links.size).to eq(page_link_size)
          end

          it "直前のコンテンツのlatestはtrueであること" do
            @page_content_just_before.send(:clear_history)
            expect(@page_content_just_before.reload.latest).to be_true
          end

          it "直前のコンテンツのPageLinkが削除されないこと" do
            @page_content_just_before.send(:clear_history)
            expect(@page_content_just_before.reload.links.size).to eq(page_link_size)
          end

          it "過去のコンテンツのlatestがfalseになること" do
            @page_content.send(:clear_history)
            @page_content_histories.each do |h|
              expect(h.reload.latest).to be_false
            end
          end

          it "過去のコンテンツのPageLinkが削除されること" do
            expect{ @page_content.send(:clear_history) }.to change(PageLink, :count).by(-1 * (page_content_size - 1) * page_link_size)
            @page_content_histories.each do |h|
              expect(h.reload.links.size).to eq(0)
            end
          end

        end
      end
    end

    describe "#cleanup" do
      it 'blockquoteタグは削除されること' do
        actual   = %{A1\n<blockquote>\nB1\n<blockquote>B2</blockquote>\nB3\n</blockquote>\nA2<blockquote>B4</blockquote>A3<BLOCKQUOTE>B5</BLOCKQUOTE>A4}
        expected = %{A1\n\nA2A3A4}
        expect(subject.send(:cleanup, actual)).to eq expected
      end

      it '文字参照、数値参照は変換されないこと' do
        actual   = %{ &lt;&gt;&amp;&quot;&nbsp;&copy;&reg; &#60;&#62;&#38;&#34;&#160;&#169;&#174; }
        expected = %{ &lt;&gt;&amp;&quot;&nbsp;&copy;&reg; &#60;&#62;&#38;&#34;&#160;&#169;&#174; }
        expect(subject.send(:cleanup, actual)).to eq expected
      end
    end

    describe "#plugin_erb_to_tag" do
      it '引数を持たないプラグインが正しく変換されること' do
        actual   = %Q(<%= plugin('form_text') %>)
        expected = %Q(<button class='editable data-type-plugin' name='form_text' value=''>#{I18n.t('widgets.items.form_text')}</button>)
        expect(subject.send(:plugin_erb_to_tag, actual)).to eq expected
      end

      it '引数を持つプラグインが正しく変換されること' do
        actual   = %Q(<%= plugin('form_text', 'あ', 'い') %>)
        expected = %Q(<button class='editable data-type-plugin' name='form_text' value='あ,い'>#{I18n.t('widgets.items.form_text')}</button>)
        expect(subject.send(:plugin_erb_to_tag, actual)).to eq expected
      end
    end
  end
end
