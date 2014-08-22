require 'spec_helper'

describe "Susanoo::AccessibilityChecker" do
  describe "メソッド" do

   let!(:checker) { Susanoo::AccessibilityChecker.new }
   let!(:default_options) {
      {
        michecker: false, block: false, alt: false,
        blank: false, style: false, link: false, text: false
      }
    }

    describe "#run" do
      shared_examples_for "検証結果正常" do
        it "エラー・警告が返らないこと" do
          checker.run(target, options)
          expect(checker.errors.size).to eq(0)
          expect(checker.warnings.size).to eq(0)
        end
      end

      shared_examples_for "検証結果異常" do |errid|
        it "エラーコード#{errid}が返ること" do
          checker.run(target, options)
          expect(checker.errors.map {|e| e[:id] }).to include(errid)
        end
      end

      shared_examples_for "検証結果警告" do |errid|
        it "警告コード#{errid}が返ること" do
          checker.run(target, options)
          expect(checker.warnings.map {|e| e[:id] }).to include(errid)
        end

        it "エラーが返らないこと" do
          checker.run(target, options)
          expect(checker.errors.size).to eq(0)
        end
      end

      shared_examples_for "検証結果要判断" do |errid|
        it "要判断コード#{errid}が返ること" do
          checker.run(target, options)
          expect(checker.users.map {|e| e[:id] }).to include(errid)
        end

        it "エラーが返らないこと" do
          checker.run(target, options)
          expect(checker.errors.size).to eq(0)
        end
      end

      describe "block" do
        let!(:options) { default_options.merge(block: true) }

        describe "見出し" do
          context "見出しが35文字を超える" do
            context "見出しタグ内がテキストのみの場合" do
              let!(:target) { html(%Q!<h1>#{'H' * 36}</h1>!) }

              it_behaves_like("検証結果異常", 'E_1_1')
            end

            context "見出しタグ内に複数のタグがある場合" do
              let!(:target) { html(%Q!<h1><span>#{'A' * 30}</span><span>#{'B' * 6}</span></h1>!) }

              it_behaves_like("検証結果異常", 'E_1_1')
            end
          end

          context "見出しが35文字の場合" do
            context "見出しタグ内がテキストのみの場合" do
              let!(:target) { html(%Q!<h1>#{'H' * 35}</h1>!) }

              it_behaves_like("検証結果正常")
            end

            context "見出しタグ内に複数のタグがある場合" do
              let!(:target) { html(%Q!<h1><span>#{'A' * 30}</span><span>#{'B' * 5}</span></h1>!) }

              it_behaves_like("検証結果正常")
            end
          end

          context "見出しに改行が含まれる場合" do
            let!(:target) { html(%Q!<h1>hhhhhh<br>hhhh</h1>!) }

            it_behaves_like("検証結果異常", 'E_1_2')
          end
        end

        describe "ブロック要素" do
          context "ブロック要素の文字数が3000を超える" do
            context "ブロック要素内が単一のタグの場合" do
              let!(:target) {
                src =  %Q!<h1>H1</h1>!
                src << div_block("<p>#{ 'X' * 3001 }</p>")
                html(src)
              }

              it_behaves_like("検証結果異常", 'E_1_4')
            end

            context "ブロック要素内が複数のタグの場合" do
              let!(:target) {
                src =  %Q!<h1>H1</h1>!
                src << div_block("<p>#{ 'X' * 2990 }</p><span><p>#{ 'X' * 11 }</p></span>")
                html(src)
              }

              it_behaves_like("検証結果異常", 'E_1_4')
            end
          end

          context "ブロック要素の文字数が1000を超える" do
            context "ブロック要素内が単一のタグの場合" do
              let!(:target) {
                src =  %Q!<h1>H1</h1>!
                src << div_block("<p>#{ 'X' * 1001 }</p>")
                html(src)
              }

              it_behaves_like("検証結果警告", 'W_1_1')
            end

            context "ブロック要素内が複数のタグの場合" do
              let!(:target) {
                src =  %Q!<h1>H1</h1>!
                src << div_block("<p>#{ 'X' * 990 }</p><span><p>#{ 'X' * 11 }</p></span>")
                html(src)
              }

              it_behaves_like("検証結果警告", 'W_1_1')
            end
          end

          context "ブロック要素の文字数が1000文字の場合" do
            context "ブロック要素内が単一のタグの場合" do
              let!(:target) {
                src =  %Q!<h1>H1</h1>!
                src << div_block("<p>#{ 'X' * 1000 }</p>")
                html(src)
              }

              it_behaves_like("検証結果正常")
            end

            context "ブロック要素内が複数のタグの場合" do
              let!(:target) {
                src =  %Q!<h1>H1</h1>!
                src << div_block("<p>#{ 'X' * 990 }</p><span><p>#{ 'X' * 10 }</p></span>")
                html(src)
              }

              it_behaves_like("検証結果正常")
            end
          end
        end

        describe "表" do
          context "tableタグにthがない場合" do
            let!(:target) {
              src =  %Q!<h1>H1</h1>!
              src << div_block("<table><tr><td>TD</td></tr></table>")
              html(src)
            }

            it_behaves_like("検証結果異常", 'C_331.0')
          end

          context "tableタグにthがある場合" do
            let!(:target) {
              src =  %Q!<h1>H1</h1>!
              src << div_block("<table><tr><th>TH</th><td>TD</td></tr></table>")
              html(src)
            }

            it_behaves_like("検証結果正常")
          end
        end

        describe "見出し・ブロック要素の関連" do
          describe "先頭の要素" do
            context "見出し" do
              context "見出しタグ h1 の場合" do
                let!(:target) { html(%Q!<h1>H1</h1><p>test</p>!) }

                it_behaves_like("検証結果正常")
              end

              context "タグに囲まれた見出しタグ h1 の場合" do
                let!(:target) { html(%Q!<div><div><h1>H1</h1></div></div><p>test</p>!) }

                it_behaves_like("検証結果正常")
              end

              (2..6).each do |level|
                context "見出しタグ h#{level} の場合" do
                  let!(:target) { html(%Q!<h#{level}>H</h#{level}><p>test</p>!) }

                  it_behaves_like("検証結果異常", "E_1_8")
                end
              end
            end

            context "見出し以外" do
              context "テキストの場合" do
                let!(:target) { html(%Q!<p>test</p><h1>H1</h1>!) }

                it_behaves_like("検証結果異常", "E_1_6")
              end

              context "テキストの後ろに見出しがある場合" do
                let!(:target) { html(%Q!<div><p>test</p><h1>H1</h1></div>!) }

                it_behaves_like("検証結果異常", "E_1_6")
              end

              context "画像の場合" do
                let!(:target) { html(%Q!<div><img src='test.png' alt='test'></div><h1>H1</h1>!) }

                it_behaves_like("検証結果異常", "E_1_6")
              end

              context "プラグインの場合" do
                let!(:target) {
                  src = plugin_block('test')
                  src << "<h1>H1</h1>"
                  html(src)
                }

                it_behaves_like("検証結果異常", "E_1_6")
              end
            end
          end

          describe "見出しの連続" do
            describe "同レベル" do
              (1..6).each do |level|
                let(:target) { html(@text) }

                context "連続する見出しタグ h#{level} の間に本文がある場合" do
                  before do
                    @text = ''
                    level.times { |l| @text << "<h#{l+1}>H</h#{l+1}/>"}
                  end

                  context "本文がテキストの場合" do
                    before do
                      @text << div_block('<p>ABC</p>')
                      @text << "<h#{level}>H</h#{level}/>"
                    end

                    it_behaves_like("検証結果正常")
                  end

                  context "本文が画像のみの場合" do
                    before do
                      @text << div_block("<img src='text.png'>")
                      @text << "<h#{level}>H</h#{level}/>"
                    end

                    it_behaves_like("検証結果正常")
                  end

                  context "本文がスペースの場合" do
                    before do
                      @text << div_block('<p>&nbsp;</p>')
                      @text << "<h#{level}>H</h#{level}/>"
                    end

                    it_behaves_like("検証結果正常")
                  end

                  context "本文が改行のみの場合" do
                    before do
                      @text << div_block("<p>\n </p>")
                      @text << "<h#{level}>H</h#{level}/>"
                    end

                    it_behaves_like("検証結果異常", 'E_1_7')
                  end
                end

                context "連続する見出しタグ h#{level} の間に本文がない場合" do
                  before do
                    @text = ''
                    level.times { |l| @text << "<h#{l+1}>H</h#{l+1}/>"}
                    @text << "<h#{level}>H</h#{level}/>"
                  end

                  it_behaves_like("検証結果異常", 'E_1_7')
                end
              end
            end

            describe "レベル降下" do
              context "連続する見出しタグのレベルが1づつ下がる場合" do
                let!(:target) {
                  src = ""
                  (1..6).each { |l| src << "<h#{l}>H</h#{l}/>"}
                  html(src)
                }

                it_behaves_like("検証結果正常")
              end

              (2..5).each do |down_level|
                context "連続する見出しタグのレベルが #{down_level} 下がる場合" do
                  let!(:target) {
                    src =  "<div><h1>H</h1/></div>"
                    src << "<h#{1+down_level}>H</h#{1+down_level}/>"
                    html(src)
                  }
                  it_behaves_like("検証結果異常", "E_1_8")
                end
              end
            end

            describe "レベル上昇" do
              (2..6).each do |level|
                let(:target) { html(@text) }

                context "連続する見出しタグ h#{level} と　h#{level-1} 間に本文がある場合" do
                  before do
                    @text = "<h1>1</h1>"
                    (level - 1).times { |l| @text << "<h#{l+2}>H</h#{l+2}/>"}
                  end

                  context "本文がテキストの場合" do
                    before do
                      @text << div_block('<p>ABC</p>')
                      @text << "<h#{level-1}>H</h#{level-1}/>"
                    end

                    it_behaves_like("検証結果正常")
                  end

                  context "本文が画像のみの場合" do
                    before do
                      @text << div_block("<img src='text.png'>")
                      @text << "<h#{level-1}>H</h#{level-1}/>"
                    end

                    it_behaves_like("検証結果正常")
                  end

                  context "本文がスペースの場合" do
                    before do
                      @text << div_block('<p>&nbsp;</p>')
                      @text << "<h#{level-1}>H</h#{level-1}/>"
                    end

                    it_behaves_like("検証結果正常")
                  end

                  context "本文が改行のみの場合" do
                    before do
                      @text << div_block("<p>\n </p>")
                      @text << "<h#{level-1}>H</h#{level-1}/>"
                    end

                    it_behaves_like("検証結果異常", 'E_1_9')
                  end
                end

                context "連続する見出しタグ h#{level} と　h#{level-1} 間に本文がない場合" do
                  before do
                    @text = "<h1>1</h1>"
                    (level - 1).times { |l| @text << "<h#{l+2}>H</h#{l+2}/>"}
                    @text << "<h#{level-1}>H</h#{level-1}/>"
                  end

                  it_behaves_like("検証結果異常", "E_1_9")
                end
              end
            end
          end
        end
      end

      describe "alt" do
        let(:options) { default_options.merge(alt: true) }

        context "alt属性がない場合" do
          let(:target) { html(%Q!<div><img src='src'/></div>!) }
          it_behaves_like("検証結果異常", "E_2_1")
        end

        context "altの値が空の場合" do
          let(:target) { html(%Q!<div><img alt src='src'/></div>!) }
          it_behaves_like("検証結果異常", "E_2_1")
        end

        context "altの値が半角・全角空白の場合" do
          let(:target) { html(%Q!<div><img alt='　\s　' /></div>!) }
          it_behaves_like("検証結果異常", "E_2_1")
        end

        context "altの値が２文字の場合" do
          let(:target) { html(%Q!<div><img alt='#{'x' * 2}' src='x'/></div>!) }
          it_behaves_like("検証結果異常", "E_2_2")
        end

        context "altの値が3文字の場合" do
          let(:target) { html(%Q!<div><img alt='#{'x' * 3}' src='x'/></div>!) }
          it_behaves_like("検証結果正常")
        end

        context "altの値が149文字の場合" do
          let(:target) { html(%Q!<div><img alt='#{'x' * 149}' src='x'/></div>!) }
          it_behaves_like("検証結果正常")
        end

        context "altの値が150文字の場合" do
          let(:target) { html(%Q!<div><img alt='#{'x' * 150}' src='x'/></div>!) }
          it_behaves_like("検証結果異常", "E_2_2")
        end
      end

      describe "blank" do
        let(:options) { default_options.merge(blank: true) }

        subject { checker.run(target, options) }

        describe "テキスト要素" do
          context "行頭以外に空白を含む場合" do
            let(:target) { html(%Q!<div><p>あい うえお</p><p>かき&nbsp;くけこ</p><p>さし　すせそ</p</div>!) }

            it_behaves_like("検証結果正常")

            it "空白が除去されること" do
              expect(subject).to eq(result_html("<div><p>あいうえお</p><p>かきくけこ</p><p>さしすせそ</p></div>"))
            end
          end

          context "要素内にテキストが複数ある場合" do
            let(:target) { html(%Q!<div><p>　あいう えお<span>1</span>　かきく　けこ<span>2</span>　さしす&nbsp;せそ</p></div>!) }

            it_behaves_like("検証結果正常")

            it "2番目以降のテキストの先頭全角空白は除去されること" do
              expect(subject).to eq(result_html("<div><p>　あいうえお<span>1</span>かきくけこ<span>2</span>さしすせそ</p></div>"))
            end
          end

          context "行頭に空白を含む場合" do
            let(:target) { html(%Q!<div><p> あいうえお</p></div>!) }

            it_behaves_like("検証結果正常")

            it "空白が除去されること" do
              expect(subject).to eq(result_html(%Q!<div><p>あいうえお</p></div>!))
            end
          end

          context "行頭に全角空白を含む場合" do
            let(:target) { html(%Q!<div><p>　あいうえお</p></div>!) }

            it_behaves_like("検証結果正常")

            it "全角空白が除去されないこと" do
              expect(subject).to eq(result_html(%Q!<div><p>　あいうえお</p></div>!))
            end
          end

          context "行頭に&nbsp;を含む場合" do
            let(:target) { html(%Q!<div><p>&nbsp;あいうえお</p></div>!) }

            it_behaves_like("検証結果正常")

            it "空白が除去されること" do
              expect(subject).to eq(result_html(%Q!<div><p>あいうえお</p></div>!))
            end
          end

          context "<p>&nbsp;</p>の場合" do
            let(:target) { html(%Q!<div><p>&nbsp;</p></div>!) }

            it_behaves_like("検証結果正常")

            it "空白が除去されないこと" do
              expect(subject).to eq(result_html(%Q!<div><p>&nbsp;</p></div>!))
            end
          end
        end

        describe "span タグの lang 属性" do
          context "lang 属性を持つ span タグ内の行頭以外に空白がある場合" do
            let(:target) { html(%Q!<div><p><span lang='en'>this is a pen</span></p></div>!) }

            it_behaves_like("検証結果正常")

            it "空白が除去されないこと" do
              expect(subject).to eq(result_html(%Q!<div><p><span lang='en'>this is a pen</span></p></div>!))
            end
          end

          context "lang 属性を持たない span タグ内の行頭以外に空白がある場合" do
            let(:target) { html(%Q!<div><p><span>this is a pen</span></p></div>!) }

            it_behaves_like("検証結果正常")

            it "空白が除去されること" do
              expect(subject).to eq(result_html(%Q!<div><p><span>thisisapen</span></p></div>!))
            end
          end
        end

        describe "img タグの alt 属性" do
          context "半角空白を含む場合" do
            let(:target) { html(%Q!<div><p><img alt='A C'></img></div>!) }

            it_behaves_like("検証結果正常")

            it "半角空白が除去されること" do
              expect(subject).to eq(result_html(%Q!<div><p><img alt='AC'></img></div>!))
            end
          end

          context "全角空白を含む場合" do
            let(:target) { html(%Q!<div><p><img alt='　AC'></img></div>!) }

            it_behaves_like("検証結果正常")

            it "全角空白が除去されること" do
              expect(subject).to eq(result_html(%Q!<div><p><img alt='AC'></img></div>!))
            end
          end
        end

        describe "table タグの summary 属性" do
          context "半角空白を含む場合" do
            let(:target) { html(%Q!<div><p><table summary='A C'></img></div>!) }

            it_behaves_like("検証結果正常")

            it "半角空白が除去されること" do
              expect(subject).to eq(result_html(%Q!<div><p><table summary='AC'></img></div>!))
            end
          end

          context "全角空白を含む場合" do
            let(:target) { html(%Q!<div><p><table summary='AC　'></img></div>!) }

            it_behaves_like("検証結果正常")

            it "全角空白が除去されること" do
              expect(subject).to eq(result_html(%Q!<div><p><table summary='AC'></img></div>!))
            end
          end
        end
      end

      describe "style" do
        let(:options) { default_options.merge(style: true) }

        describe "font-size" do
          let(:target) { html(%Q!<div><p style='font-size:10#{unit};color:red;'>あいうえお</p></div>!) }

          %w(% em).each do |u|
            context "#{u}を含む場合" do
              let(:unit) { u }

              it_behaves_like("検証結果正常")
            end
          end

          %w(px pt ex).each do |u|

            context "#{u}を含む場合" do
              let(:unit) { u }

              it_behaves_like("検証結果異常", "E_4_1")
            end
          end
        end

        describe "フォントの指定方法" do
          let(:target) { html(%Q!<div><p style='font: bold 10#{unit} serif;color:red;'>あいうえお</p></div>!) }

          %w(% em).each do |u|
            context "#{u}を含む場合" do
              let(:unit) { u }

              it_behaves_like("検証結果正常")
            end
          end

          %w(px pt ex).each do |u|
            context "#{u}を含む場合" do
              let(:unit) { u }

              it_behaves_like("検証結果異常", "E_4_1")
            end
          end
        end
      end

      describe "リンク" do
        let(:options) { default_options.merge(link: true) }

        describe "連続するリンク" do
          context "空白以外を挟んで a タグが連続する場合" do
            let(:target) { html(%Q!<div><a href='/index1.html'>1</a>あ<a href='/index2.html'>2</a></div>!) }

            it_behaves_like("検証結果正常")
          end

          context "リンクが連続する場合" do
            let(:target) { html(%Q!<div><a href='/index1.html'>1</a><a href='/index2.html'>2</a></div>!) }

            it_behaves_like("検証結果異常", "E_5_2")
          end

          context "リンクが空白を挟んで連続する場合" do
            let(:target) { html(%Q!<div><a href='/index1.html'>1</a>\s　&nbsp;<a href='/index2.html'>2</a></div>!) }

            it_behaves_like("検証結果異常", "E_5_3")
          end
        end

        describe "リンク先のコンテンツ" do
          context "音声の場合" do
            let(:target) { html(%Q!<div><a href='/index1.mp3'>1</a></div>!) }

            it_behaves_like("検証結果異常", "E_5_4")
          end

          context "動画の場合" do
            let(:target) { html(%Q!<div><a href='/index1.avi'>1</a></div>!) }

            it_behaves_like("検証結果異常", "E_5_4")
          end
        end

        describe "リンク先のURL" do
          context "外部リンク" do
            let(:href) { "http://www.netlab.jp/" }

            describe "a タグ内のテキスト" do
              context "外部サイトを含む場合" do
                let(:target) { html(%Q!<div><a href='#{href}'>外部サイトです</a></div>!) }

                it_behaves_like("検証結果正常")
              end

              context "外部サイトを含まない場合" do
                let(:target) { html(%Q!<div><a href='#{href}'>あいうえお<img alt='かきくけこ' /></a></div>!) }

                it_behaves_like("検証結果異常", "E_5_1")
              end
            end

            describe "img タグの alt 属性" do
              context "外部サイトを含む場合" do
                let(:target) { html(%Q!<div><a href='#{href}'><img alt='外部サイト' /></a></div>!) }

                it_behaves_like("検証結果正常")
              end

              context "外部サイトを含まない場合" do
                let(:target) { html(%Q!<div><a href='#{href}'><img alt='XXXX' /></a></div>!) }

                it_behaves_like("検証結果異常", "E_5_1")
              end
            end
          end

          context "全角文字,半角空白を含む URL" do
            let(:target) { html(%Q!<div><a href='http://www. 外部サイト .jp'>外部サイト</a></div>!) }

            it_behaves_like("検証結果正常")

            it "検証が例外で中断しないこと" do
              expect{ checker.run(target, options) }.not_to raise_error
            end
          end

          context "誤った URL を含む" do
            let(:target) { html(%Q!<div><a href='www.tei-kei-wj.co,jp#5#5'>あいうえお<img alt='かきくけこ' /></a></div>!) }

            it_behaves_like("検証結果正常")

            it "検証が例外で中断しないこと" do
              expect{ checker.run(target, options) }.not_to raise_error
            end
          end

          context "mailto を含む" do
            let(:target) { html(%Q!<div><a href='mailto:foo@pref.shimane.lg.jp?subject=[TEIAN No.357]'>あいうえお<img alt='かきくけこ' /></a></div>!) }

            it_behaves_like("検証結果正常")

            it "検証が例外で中断しないこと" do
              expect{ checker.run(target, options) }.not_to raise_error
            end
          end

          context "誤った mailto を含む" do
            let(:target) { html(%Q!<div><a href=mailto:→foo@pref.shimane.lg.jp'>あいうえお<img alt='かきくけこ' /></a></div>!) }

            it_behaves_like("検証結果正常")

            it "検証が例外で中断しないこと" do
              expect{ checker.run(target, options) }.not_to raise_error
            end
          end

          context "JavaScript を含む" do
            let(:target) { html(%Q!<div><a href="javascript:void fnHonLink(2894,'m1010136041511251.html','TOP')">あいうえお<img alt='かきくけこ' /></a></div>!) }

            it_behaves_like("検証結果正常")

            it "検証が例外で中断しないこと" do
              expect{ checker.run(target, options) }.not_to raise_error
            end
          end
        end
      end

      describe "テキスト" do
        let(:options) { default_options.merge(text: true) }

        context "機種依存文字を含まない場合" do
          let(:target) { html(%Q!<div><p>(1)</a></div>!) }

          it_behaves_like("検証結果正常")
          it_behaves_like("検証結果要判断", "U_6_1")
        end

        context "機種依存文字を含む場合" do
          let(:target) { html(%Q!<div><p>①</a></div>!) }

          it_behaves_like("検証結果異常", "E_6_1")
        end
      end

      describe "エラーの例外扱い" do
        let(:options) { default_options.merge(block: true) }

        shared_examples_for "例外検証" do
          it "例外登録したエラーが返らないこと" do
            target = html("<div><p>1</p></div><div><h1>h1</h1></div>")
            checker.run(target, options)
            expect(checker.errors.size).to eq(0)
          end
        end

        shared_examples_for "未登録例外検証" do
          it "例外登録していないエラーが返ること" do
            target = html("<div><h1>h1</h1></div><div><h1>h1</h1></div>")
            checker.run(target, options)
            expect(checker.errors[0][:id]).to eq('E_1_7')
          end
        end

        shared_examples_for "パス不一致時の例外検証" do
          it "例外登録したエラーが返えること" do
            target = html("<div><p>1</p></div><div><h1>h1</h1></div>")
            checker.run(target, options)
            expect(checker.errors[0][:id]).to eq('E_1_6')
          end
        end

        context "登録したパスと一致するパスの場合" do
          let(:checker) { Susanoo::AccessibilityChecker.new(path: '/') }
          it_behaves_like("例外検証")
          it_behaves_like("未登録例外検証")
        end

        context "登録したパスと一致しないパスの場合" do
          let(:checker) { Susanoo::AccessibilityChecker.new(path: '/test.html') }
          it_behaves_like("パス不一致時の例外検証")
        end

        context "登録したパス直下の場合" do
          let(:checker) { Susanoo::AccessibilityChecker.new(path: '/life/') }
          it_behaves_like("例外検証")
          it_behaves_like("未登録例外検証")
        end

        context "登録したパスの指定した階層内の場合" do
          let(:checker) { Susanoo::AccessibilityChecker.new(path: '/life/1/2/3.thml') }
          it_behaves_like("例外検証")
          it_behaves_like("未登録例外検証")
        end

        context "登録したパスの指定した階層外の場合" do
          let(:checker) { Susanoo::AccessibilityChecker.new(path: '/life/1/2/3/4.thml') }
          it_behaves_like("パス不一致時の例外検証")
        end
      end
    end
  end

  def html(content)
    h =  %Q(<html><body>)
    h += %Q(<div id='#{Settings.page_content.wrapper_id}'>)
    h += %Q(<div id='page-content'>)
    h += %Q(<div class='#{PageContent.editable_class[:field]}'>)
    h += content
    h += %Q(</div></div></div></body></html>)
  end

  def result_html(content)
    h =  %Q(<div id='#{Settings.page_content.wrapper_id}'>)
    h += %Q(<div id='page-content'>)
    h += %Q(<div class='#{PageContent.editable_class[:field]}'>)
    h += content
    h += %Q(</div></div></div>)

    doc = Nokogiri.HTML(h)
    doc.at_css("\##{Settings.page_content.wrapper_id}").children.to_xhtml
  end

  def div_block(content)
    %Q(<div class='editable data-type-div'>#{content}</div>)
  end

  def heading_block(content)
    %Q(<div class='editable data-type-h'>#{content}</div>)
  end

  def plugin_block(content)
    %Q(<button class='editable data-type-plugin'>#{content}</button>)
  end

end
