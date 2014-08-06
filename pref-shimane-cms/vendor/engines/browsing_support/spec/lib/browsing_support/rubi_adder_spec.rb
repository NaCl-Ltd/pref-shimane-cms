require 'spec_helper'

describe "BrowsingSupport::RubiAdder" do

  describe 'メソッド' do
    describe '.add' do
      it "ルビがふられた html が返されること" do
        html =<<__HTML__
<html>
<head>
  <title>MeCabでの態素解析</title>
</head>
<body>
MeCabで形態素解析を行うとこうなる。
<div>
太郎はこの本を二郎を見た女性に渡した。
</div>
</body>
</html>
__HTML__

        expected =<<__RUBY_HTML__
<html>
<head>
  <title>MeCabでの態素解析</title>
</head>
<body>
MeCabで<ruby>形態素<rp>(</rp><rt>けいたいそ</rt><rp>)</rp></ruby><ruby>解析<rp>(</rp><rt>かいせき</rt><rp>)</rp></ruby>を<ruby>行<rp>(</rp><rt>おこな</rt><rp>)</rp></ruby>うとこうなる。
<div>
<ruby>太郎<rp>(</rp><rt>たろう</rt><rp>)</rp></ruby>はこの<ruby>本<rp>(</rp><rt>ほん</rt><rp>)</rp></ruby>を二郎を<ruby>見<rp>(</rp><rt>み</rt><rp>)</rp></ruby>た<ruby>女性<rp>(</rp><rt>じょせい</rt><rp>)</rp></ruby>に<ruby>渡<rp>(</rp><rt>わた</rt><rp>)</rp></ruby>した。
</div>
</body>
</html>
__RUBY_HTML__

        expect(BrowsingSupport::RubiAdder.add(html)).to eq expected
      end

      it "<ruby>タグで囲まれた箇所はルビはふられないこと" do
        html =<<__HTML__
<html>
<head>
  <title>MeCabでの態素解析</title>
</head>
<body>
<ruby>MeCabで形態素解析を行うとこうなる。</ruby>
<div>
太郎はこの本を二郎を見た女性に渡した。
</div>
</body>
</html>
__HTML__

        expected =<<__RUBY_HTML__
<html>
<head>
  <title>MeCabでの態素解析</title>
</head>
<body>
<ruby>MeCabで形態素解析を行うとこうなる。</ruby>
<div>
<ruby>太郎<rp>(</rp><rt>たろう</rt><rp>)</rp></ruby>はこの<ruby>本<rp>(</rp><rt>ほん</rt><rp>)</rp></ruby>を二郎を<ruby>見<rp>(</rp><rt>み</rt><rp>)</rp></ruby>た<ruby>女性<rp>(</rp><rt>じょせい</rt><rp>)</rp></ruby>に<ruby>渡<rp>(</rp><rt>わた</rt><rp>)</rp></ruby>した。
</div>
</body>
</html>
__RUBY_HTML__

        expect(BrowsingSupport::RubiAdder.add(html)).to eq expected
      end

      it "送り仮名はルビの対象に含まれないこと" do
        # 下記例では お祭りの「り」、行きの「き」が送り仮名
        expect(
          BrowsingSupport::RubiAdder.add("昨日わたしはお祭りに行きました。")
        ).to eq(
          "<ruby>昨日<rp>(</rp><rt>きのう</rt><rp>)</rp></ruby>わたしはお<ruby>祭<rp>(</rp><rt>まつ</rt><rp>)</rp></ruby>りに<ruby>行<rp>(</rp><rt>い</rt><rp>)</rp></ruby>きました。"
        )
      end

      describe '辞書' do
        let(:user_csv) { Pathname.new(Word.dicdir).join('user.csv') }
        let(:user) { create(:user) }

        after do
          FileUtils.rm( File.join(Word.dicdir, 'user.csv') )
          Word.run_mecab_dict_index
        end

        it "期待したルビがふられること" do
          word = create(:word, base: '匹見峡', text: 'ひきみきょう', user: user)
          expected = %{<ruby>匹見峡<rp>(</rp><rt>ひきみきょう</rt><rp>)</rp></ruby>}

          expect( BrowsingSupport::RubiAdder.add(word.base) ).to_not eq expected
          Word.update_dictionary
          expect( BrowsingSupport::RubiAdder.add(word.base) ).to eq expected
        end
      end
    end
  end
end
