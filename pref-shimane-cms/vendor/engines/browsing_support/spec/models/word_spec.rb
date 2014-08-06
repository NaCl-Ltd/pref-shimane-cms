require 'spec_helper'

describe Word do
  describe "バリデーション" do
    it { should validate_presence_of :base }
    it { should validate_uniqueness_of :base }
    # テストフォーマット：/[^\s!-~　]/
    it { should allow_value([31].pack('U')).for(:base) } # # '\u001F'
    it { should_not allow_value([32].pack('U')).for(:base) }  # ' '
    it { should_not allow_value([33].pack('U')).for(:base) }  # '!'
    it { should_not allow_value([126].pack('U')).for(:base) } # '~'
    it { should allow_value([127].pack('U')).for(:base) } # '\u007F'
    it { should_not allow_value(' ').for(:base) } # '~'
    # テスト機種依存文字
    it { should_not allow_value("\u2460").for(:base) } # '①'
    it { should_not allow_value("\ufa11").for(:base) } # '﨑'
    it { should_not allow_value("\u337b").for(:base) } # '㍻'

    it { should validate_presence_of :text }
    # テストフォーマット：/[ぁ-ん]/
    it { should_not allow_value([12352].pack('U')).for(:text) } # '\u3040'
    it { should allow_value([12353].pack('U')).for(:text) } # 'ぁ'
    it { should allow_value([12435].pack('U')).for(:text) } # 'ん'
    it { should_not allow_value([12436].pack('U')).for(:text) } # 'ゔ'
    # テストフォーマット：/゛/
    it { should_not allow_value([12442].pack('U')).for(:text) } # ''
    it { should allow_value([12443].pack('U')).for(:text) } # '゛'
    it { should_not allow_value([12444].pack('U')).for(:text) } # '゜'
    # テストフォーマット：/ァ-ヶ/
    it { should_not allow_value([12448].pack('U')).for(:text) } # '゠'
    it { should allow_value([12449].pack('U')).for(:text) } # 'ァ'
    it { should allow_value([12534].pack('U')).for(:text) } # 'ヶ'
    it { should_not allow_value([12535].pack('U')).for(:text) } # 'ヷ'
    # テストフォーマット：/ー/
    it { should_not allow_value([12539].pack('U')).for(:text) } # '・'
    it { should allow_value([12540].pack('U')).for(:text) } # 'ー'
    it { should_not allow_value([12541].pack('U')).for(:text) } # 'ヽ'
    # テスト機種依存文字
    it { should_not allow_value("\u2460").for(:text) } # '①'
    it { should_not allow_value("\u337b").for(:text) } # '㍻'
    it { should_not allow_value("\ufa11").for(:text) } # '﨑'

    describe 'attribute :base' do
      it 'JIS X 0208 の13区は機種依存文字として扱われること' do
        chars = []
        chars.concat %w(① ② ③ ④ ⑤ ⑥ ⑦ ⑧ ⑨ ⑩)
        chars.concat %w(⑪ ⑫ ⑬ ⑭ ⑮ ⑯ ⑰ ⑱ ⑲ ⑳)
        chars.concat %w(Ⅰ Ⅱ Ⅲ Ⅳ Ⅴ Ⅵ Ⅶ Ⅷ Ⅸ Ⅹ)
        chars.concat %w(㍉ ㌔ ㌢ ㍍ ㌘ ㌧ ㌃ ㌶ ㍑ ㍗ ㌍ ㌦ ㌣ ㌫ ㍊ ㌻)
        chars.concat %w(㎜ ㎝ ㎞ ㎎ ㎏ ㏄ ㎡)
        chars.concat %w(㍻ 〝 〟 № ㏍ ℡ ㊤ ㊥ ㊦ ㊧ ㊨ ㈱ ㈲ ㈹ ㍾ ㍽ ㍼)
        chars.concat %w(∮ ∑ ∟ ⊿)
        subject.base = chars.join
        subject.valid?
        expect(subject.errors.full_messages_for(:base)).to include(
          subject.errors.full_message(:base,
            subject.errors.generate_message(:base, :invalid_chars, chars: chars.map{|c| '&#%d;' % c.ord}.join(','))
          )
        )
      end

      it 'JIS X 0208 の89区は機種依存文字として扱われること' do
        chars = []
        chars.concat %w(纊 褜 鍈 銈 蓜 俉 炻 昱 棈 鋹 曻 彅 丨 仡 仼 伀 伃 伹)
        chars.concat %w(佖 侒 侊 侚 侔 俍 偀 倢 俿 倞 偆 偰 偂 傔 僴 僘 兊 兤)
        chars.concat %w(冝 冾 凬 刕 劜 劦 勀 勛 匀 匇 匤 卲 厓 厲 叝 﨎 咜 咊)
        chars.concat %w(咩 哿 喆 坙 坥 垬 埈 埇 﨏 塚 增 墲 夋 奓 奛 奝 奣 妤)
        chars.concat %w(妺 孖 寀 甯 寘 寬 尞 岦 岺 峵 崧 嵓 﨑 嵂 嵭 嶸 嶹 巐)
        chars.concat %w(弡 弴 彧 德)
        subject.base = chars.join
        subject.valid?
        expect(subject.errors.full_messages_for(:base)).to include(
          subject.errors.full_message(:base,
            subject.errors.generate_message(:base, :invalid_chars, chars: chars.map{|c| '&#%d;' % c.ord}.join(','))
          )
        )
      end

      it 'JIS X 0208 の91区は機種依存文字として扱われること' do
        chars = []
        chars.concat %w(忞 恝 悅 悊 惞 惕 愠 惲 愑 愷 愰 憘 戓 抦 揵 摠 撝 擎)
        chars.concat %w(敎 昀 昕 昻 昉 昮 昞 昤 晥 晗 晙 晴 晳 暙 暠 暲 暿 曺)
        chars.concat %w(朎 朗 杦 枻 桒 柀 栁 桄 棏 﨓 楨 﨔 榘 槢 樰 橫 橆 橳)
        chars.concat %w(橾 櫢 櫤 毖 氿 汜 沆 汯 泚 洄 涇 浯 涖 涬 淏 淸 淲 淼)
        chars.concat %w(渹 湜 渧 渼 溿 澈 澵 濵 瀅 瀇 瀨 炅 炫 焏 焄 煜 煆 煇)
        chars.concat %w(凞 燁 燾 犱)
        subject.base = chars.join
        subject.valid?
        expect(subject.errors.full_messages_for(:base)).to include(
          subject.errors.full_message(:base,
            subject.errors.generate_message(:base, :invalid_chars, chars: chars.map{|c| '&#%d;' % c.ord}.join(','))
          )
        )
      end

      it 'JIS X 0208 の92区は機種依存文字として扱われること' do
        chars = []
        chars.concat %w(釗 釞 釭 釮 釤 釥 鈆 鈐 鈊 鈺 鉀 鈼 鉎 鉙 鉑 鈹 鉧 銧)
        chars.concat %w(鉷 鉸 鋧 鋗 鋙 鋐 﨧 鋕 鋠 鋓 錥 錡 鋻 﨨 錞 鋿 錝 錂)
        chars.concat %w(鍰 鍗 鎤 鏆 鏞 鏸 鐱 鑅 鑈 閒 隆 﨩 隝 隯 霳 霻 靃 靍)
        chars.concat %w(靏 靑 靕 顗 顥 飯 飼 餧 館 馞 驎 髙 髜 魵 魲 鮏 鮱 鮻)
        chars.concat %w(鰀 鵰 鵫 鶴 鸙 黑)
        chars.concat %w(ⅰ ⅱ ⅲ ⅳ ⅴ ⅵ ⅶ ⅷ ⅸ ⅹ ￤ ＇ ＂)
        subject.base = chars.join
        subject.valid?
        expect(subject.errors.full_messages_for(:base)).to include(
          subject.errors.full_message(:base,
            subject.errors.generate_message(:base, :invalid_chars, chars: chars.map{|c| '&#%d;' % c.ord}.join(','))
          )
        )
      end
    end
  end

  describe "コールバック" do
    describe "save" do
      it "読みはカタカナとして保存されること" do
        word = build(:word)
        word.text = 
          ('ぁ'..'ん').step(1).to_a.join +
          "゛" +
          ('ァ'..'ヶ').step(1).to_a.join +
          "ー" +
          "う゛"

        word.save!
        expect(word.text).to eq(
          ('ァ'..'ン').step(1).to_a.join +
          "゛" +
          ('ァ'..'ヶ').step(1).to_a.join +
          "ー" +
          "ヴ"
        )
      end
    end
  end

  describe "メソッド" do
    describe ".last_modified" do
      context "レコードが1件以上の登録されている場合" do
        before do
          @word1 = create(:word, updated_at: Time.now - 1800).reload
          @word2 = create(:word, updated_at: Time.now - 60).reload
          @word3 = create(:word, updated_at: Time.now - 3600).reload
        end

        it "最後に更新された単語の更新時刻を返すこと" do
          expect(Word.last_modified).to eq @word2.updated_at
        end
      end

      context "レコードが1件の登録されていない場合" do
        before do
          Word.delete_all
        end

        it "起算時の時刻を返すこと" do
          expect(Word.last_modified).to eq Time.at(0)
        end
      end
    end

    describe ".get_paginate" do
      subject{ Word.get_paginate(params) }

      context "検索" do
        before do
          @word_AA = create(:word, base: 'かか', text: 'ああ')
          @word_AI = create(:word, base: 'かき', text: 'あい')
          @word_IA = create(:word, base: 'きか', text: 'いあ')
          @word_II = create(:word, base: 'きき', text: 'いい')
          @word_aa = create(:word, base: 'がが', text: 'ぁぁ')
          @word_ai = create(:word, base: 'がぎ', text: 'ぁぃ')
          @word_ia = create(:word, base: 'ぎが', text: 'ぃぁ')
          @word_ii = create(:word, base: 'ぎぎ', text: 'ぃぃ')
        end

        context "{query_text: 'あ ぁ'} のとき" do
          let(:params) { {query_text: 'あ ぁ'} }

          it "読みが'あ'または'ぁ'から始まるレコードを返すこと" do
            words, search, query = subject
            expect(words).to match_array([@word_AA, @word_AI, @word_aa, @word_ai])
          end

          it "search = true を返すこと" do
            words, search, query = subject
            expect(search).to be_true
          end

          it "query = {} を返すこと" do
            words, search, query = subject
            expect(query).to eq({})
          end
        end

        context "{query_base: 'か', search: '1'} のとき" do
          let(:params) { {query_base: 'か', search: '1'} }

          it "単語に'か'を含むレコードを返すこと" do
            words, search, query = subject
            expect(words).to match_array([@word_AA, @word_AI, @word_IA])
          end

          it "search = true を返すこと" do
            words, search, query = subject
            expect(search).to be_true
          end

          it "query = {query_base: 'あ', search: 'search'} を返すこと" do
            words, search, query = subject
            expect(query).to eq({query_base: 'か', search: 'search'})
          end
        end

        context "{query_base: 'か', prefix_search: '1'} のとき" do
          let(:params) { {query_base: 'か', prefix_search: '1'} }

          it "単語が'か'から始まるレコードを返すこと" do
            words, search, query = subject
            expect(words).to match_array([@word_AA, @word_AI])
          end

          it "search = true を返すこと" do
            words, search, query = subject
            expect(search).to be_true
          end

          it "query = {query_base: 'あ', prefix_search: '1'} を返すこと" do
            words, search, query = subject
            expect(query).to eq({query_base: 'か', prefix_search: 'prefix_search'})
          end
        end

        context "{} のとき" do
          let(:params) { {} }

          it "全レコードを返すこと" do
            words, search, query = subject
            expect(words).to match_array(
              [@word_AA, @word_AI, @word_IA, @word_II, @word_aa, @word_ai, @word_ia, @word_ii])
          end

          it "search = false を返すこと" do
            words, search, query = subject
            expect(search).to be_false
          end

          it "query = {} を返すこと" do
            words, search, query = subject
            expect(query).to eq({})
          end
        end
      end

      context "ページネーション" do
        before do
          create_list(:word, 15)
        end

        context "{} のとき" do
          let(:params) { {} }

          it "10レコードが返ること" do
            words, search, query = subject
            expect(words).to have(10).items
          end
        end

        context "{page: 1} のとき" do
          let(:params) { {page: 1} }

          it "10レコードが返ること" do
            words, search, query = subject
            expect(words).to have(10).items
          end
        end

        context "{page: 2} のとき" do
          let(:params) { {page: 2} }

          it "5レコードが返ること" do
            words, search, query = subject
            expect(words).to have(5).items
          end
        end

        context "{page: 3} のとき" do
          let(:params) { {page: 3} }

          it "0レコードが返ること" do
            words, search, query = subject
            expect(words).to have(0).items
          end
        end
      end
    end

    describe ".update_dictionary" do
      let!(:user) { create(:user) }
      let!(:words) { create_list(:word, 3, user: user) }

      around do |example|
        Dir.mktmpdir do |dir|
          described_class.stub(:dicdir).and_return(dir)
          example.call
        end
      end

      before do
        allow(described_class).to receive(:run_mecab_dict_index)
      end

      it '#{dicdir}/user.csv に単語と読みが記述されること' do
        user_csv = Pathname.new(described_class.dicdir).join('user.csv')
        statments = words.map{|w| "#{w.base},,,3000,名詞,一般,*,*,*,*,#{w.base},#{w.text},#{w.text},1/1,1C"}

        described_class.update_dictionary
        expect(user_csv).to exist
        expect(user_csv.read(encoding: 'euc-jp')).to eq statments.join("\n") + "\n"
      end

      it '.run_mecab_dict_index を呼び出すこと' do
        expect(described_class).to receive(:run_mecab_dict_index)
        described_class.update_dictionary
      end
    end

    describe "#set_attributes" do
      before do
        @word = Word.new
        @params = {}
        @params[:word] = {}
        @params[:word][:base] = '出雲'
        @params[:word][:text] = 'いずも'
        @user = User.new(:name => 'たろう')
      end
      context "normal case." do
        it "normal set attribute" do
          @word.set_attributes(@params, @user)
          @word.base.should eql("出雲")
          @word.text.should eql("いずも")
          @word.user.should_not be_nil
        end
      end
    end

    describe "#editable_by?" do
      before do
        subject.user = registrant
      end

      context "運用管理者の場合" do
        let(:user) { create(:user) }

        context "自身が登録していた場合" do
          let(:registrant) { user }

          it "true が返ること" do
            expect(subject.editable_by?(user)).to be_true
          end
        end

        context "同じ所属のユーザが登録していた場合" do
          let(:registrant) { create(:normal_user, section: user.section) }

          it "true が返ること" do
            expect(subject.editable_by?(user)).to be_true
          end
        end

        context "異なる所属のユーザが登録していた場合" do
          let(:registrant) { create(:normal_user) }

          it "true が返ること" do
            expect(subject.editable_by?(user)).to be_true
          end
        end

        context "登録者が削除されていた場合" do
          let(:registrant) { nil }

          it "true が返ること" do
            expect(subject.editable_by?(user)).to be_true
          end
        end
      end

      context "情報提供管理者の場合" do
        let(:user) { create(:section_user) }

        context "自身が登録していた場合" do
          let(:registrant) { user }

          it "true が返ること" do
            expect(subject.editable_by?(user)).to be_true
          end
        end

        context "同じ所属のユーザが登録していた場合" do
          let(:registrant) { create(:normal_user, section: user.section) }

          it "true が返ること" do
            expect(subject.editable_by?(user)).to be_true
          end
        end

        context "異なる所属のユーザが登録していた場合" do
          let(:registrant) { create(:normal_user) }

          it "false が返ること" do
            expect(subject.editable_by?(user)).to be_false
          end
        end

        context "登録者が削除されていた場合" do
          let(:registrant) { nil }

          it "false が返ること" do
            expect(subject.editable_by?(user)).to be_false
          end
        end
      end

      context "ホームページ担当者の場合" do
        let(:user) { create(:normal_user) }

        context "自身が登録していた場合" do
          let(:registrant) { user }

          it "true が返ること" do
            expect(subject.editable_by?(user)).to be_true
          end
        end

        context "同じ所属のユーザが登録していた場合" do
          let(:registrant) { create(:normal_user, section: user.section) }

          it "true が返ること" do
            expect(subject.editable_by?(user)).to be_true
          end
        end

        context "異なる所属のユーザが登録していた場合" do
          let(:registrant) { create(:normal_user) }

          it "false が返ること" do
            expect(subject.editable_by?(user)).to be_false
          end
        end

        context "登録者が削除されていた場合" do
          let(:registrant) { nil }

          it "false が返ること" do
            expect(subject.editable_by?(user)).to be_false
          end
        end
      end
    end

    describe "#text_2h" do
      context "word.text = nil のとき" do
        before do
          subject.text = nil
        end

        it "nil を返すこと" do
          expect(subject.text_2h).to be_nil
        end
      end

      context "word.text が入力されているとき" do
        before do
          subject.text =
            ('ぁ'..'ん').step(1).to_a.join +
            "゛" +
            ('ァ'..'ヶ').step(1).to_a.join +
            "ー"
        end

        it "ひらがなに変換した読みが返ること" do
          expected =
            ('ぁ'..'ん').step(1).to_a.join +
            "゛" +
            ('ぁ'..'ん').step(1).to_a.join + "う゛ヵヶ" +
            "ー"
            # 'ヴ' は 'う゛'に変換される
          expect(subject.text_2h).to eq(expected)
        end
      end
    end
  end
end
