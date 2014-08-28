require 'spec_helper'

describe Section do
  describe "バリデーション" do
    it { should validate_presence_of :name }
    it { should validate_presence_of :code }
    context "if ftp.blank?=false" do
      subject {
        Section.new(name: "test01", code: "test01", ftp: "/invalid_ftp")
      }
      it { should have(1).errors_on(:ftp) }
    end

    context "if ftp.blank?=false" do
      before do
        section = create(:section)
        @ftp = section.ftp
      end

      subject {
        Section.new(name: "test01", code: "test01", ftp: @ftp)
      }
      it { should have(1).errors_on(:ftp) }
    end
  end

  describe "メソッド" do
    describe "#susanoo?" do
      let(:features) { Settings.section.features }

      context "Sectionの使用機能がsusanooの場合" do
        let(:section) { create(:section, feature: features.susanoo) }

        it "tureを返すこと" do
          expect(section.susanoo?).to be_true
        end
      end

      context "Sectionの使用機能がclassicの場合" do
        let(:section) { create(:section, feature: features.classic) }

        it "falseを返すこと" do
          expect(section.susanoo?).to be_false
        end
      end
    end

    describe "#classic?" do
      let(:features) { Settings.section.features }

      context "Sectionの使用機能がsusanooの場合" do
        let(:section) { create(:section, feature: features.susanoo) }

        it "falseを返すこと" do
          expect(section.classic?).to be_false
        end
      end

      context "Sectionの使用機能がclassicの場合" do
        let(:section) { create(:section, feature: features.classic) }

        it "trueを返すこと" do
          expect(section.classic?).to be_true
        end
      end
    end

    describe "#create_new_section" do
      let(:section) { build(:section_without_genres, division_id: 1, feature: 0) }

      context "バリデーションエラーが起こる" do
        it "falseが返ること" do
          section.name = nil
          expect(section.create_new_section).to be_false
        end
      end

      context "バリデーションエラーが起こらない" do
        before do
          create(:section_without_genres, division_id: 1, number: 1)
        end

        context "所属トップフォルダを指定しない" do
          subject { section.create_new_section }

          it "trueが返ること" do
            subject
            expect(subject).to be_true
          end

          it "numberが最大値となること" do
            subject
            expect(section.number).to eq(2)
          end

          it "top_genre_idがnilになること" do
            subject
            expect(section.top_genre_id).to be_nil
          end
        end

        context "所属トップフォルダを指定する" do
          context "既存のフォルダのIDを指定する" do
            let(:genre) {create(:genre) }
            subject { section.create_new_section(id: genre.id) }

            it "trueが返ること" do
              expect(subject).to be_true
            end

            it "top_genre_idが指定したフォルダのIDになること" do
              subject
              expect(section.top_genre_id).to eq(genre.id)
            end
          end

          context "フォルダ名を指定する" do
            before do
              @top_genre = create(:top_genre)
            end

            let(:genre) { Genre.where(name: name).first }
            subject { section.create_new_section(name: name) }

            context "正しい名称を指定する" do
              let(:name) { 'test0123' }

              it "trueが返ること" do
                expect(subject).to be_true
              end

              it "top_genre_idが作成したフォルダのIDになること" do
                subject
                expect(section.top_genre_id).to eq(genre.id)
              end

              it "トップフォルダ配下にフォルダが作成されること" do
                subject
                expect(@top_genre.children.first).to eq(genre)
              end
            end

            context "不正な名称を指定する" do
              let(:name) { '不正' }

              it "falseが返ること" do
                expect(subject).to be_false
              end

              it "トップフォルダ配下にフォルダが作成されないこと" do
                subject
                expect(@top_genre.children.first).to eq(genre)
              end
            end
          end
        end
      end
    end

    describe "#super_section?" do
      context "管理用所属の場合" do
        it "tureを返すこと" do
          super_section = create(:section, code: Settings.section.admin_code)
          expect(super_section.super_section?).to be_true
        end
      end

      context "管理用所属出ない場合" do
        it "falseを返すこと" do
          super_section = create(:section, code: Settings.section.admin_code)
          section = create(:section, code: Settings.section.admin_code + "@")
          expect(section.super_section?).to be_false
        end
      end
    end

    describe ".super_section" do
      it "管理用所属を返すこと" do
        super_section = create(:section, code: Settings.section.admin_code)
        expect(Section.super_section).to eq(super_section)
      end
    end

    describe ".super_section_id" do
      it "管理用所属のIDを返すこと" do
        super_section = create(:section, code: Settings.section.admin_code)
        expect(Section.super_section_id).to eq(super_section.id)
      end

    end

    describe "#generate_pages_csv" do
      let!(:division) { create(:division) }
      let!(:section1) { create(:section, division: division) }
      let!(:section2) { create(:section, division: division) }
      let!(:root)  { create(:top_genre) }
      let!(:genre1) { create(:genre, parent: root, section: section1, deletable: true) }
      let!(:g1_page1)  { create(:page_editing, genre: genre1) }
      let!(:g1_page2)  { create(:page_editing, genre: genre1) }
      let!(:child)  { create(:genre, parent: genre1, section: section1, deletable: true) }
      let!(:child_page1)  { create(:page_editing, genre: child) }
      let!(:child_page2)  { create(:page_editing, genre: child) }
      let!(:genre2) { create(:genre, parent: root, section: section2, deletable: true) }
      let!(:genre3) { create(:genre, parent: root, section: section1, deletable: true) }
      let!(:child_genre1) { create(:genre, parent: genre1, section: section1, deletable: true) }
      let!(:child_genre2) { create(:genre, parent: genre1, section: section2, deletable: true) }

      it "CSVファイルが出力されること" do
        str = []
        count = 1
        CSV.parse(section1.generate_pages_csv) do |row|
          str << row
          expect(row.last).to eq("title1") if count == 4
          expect(row.size).to eq(3) if count == 4
          expect(row.last).to eq("title3") if count == 5
          expect(row.size).to eq(3) if count == 5
          count += 1
        end
        expect(str.size).to eq(19)
      end
    end

  end
end
