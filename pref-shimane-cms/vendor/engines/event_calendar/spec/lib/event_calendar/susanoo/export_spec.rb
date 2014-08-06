require 'spec_helper'

describe EventCalendar:: Susanoo::Export do
  describe "メソッド" do
    let(:export) { Susanoo::Export.new }

    before do
      allow_any_instance_of(Susanoo::Export).to receive(:rsync)
    end

    describe "#create_event_page" do
      let(:event_top) { create(:genre, event_folder_type: ::Genre.event_folder_types[:top])}
      let(:event_page) { create(:page_publish, genre_id: event_top.id, begin_event_date: Date.new(2013, 11, 25), end_event_date: Date.new(2013, 12, 5)) }

      before do
        allow_any_instance_of(::Susanoo::Exports::PageCreator).to receive(:make).and_return(true)
        allow_any_instance_of(::Susanoo::Exports::PageCreator).to receive(:delete)
      end

      it "XmlCreatorでxmlをmakeしていること" do
        expect_any_instance_of(::EventCalendar::Susanoo::Exports::XmlCreator).to receive(:make)
        export.create_event_page(event_page.id)
      end

      it "::Susanoo::Exports::PageCreator でページをmakeしていること" do
        event_top_path = Pathname(event_top.path).cleanpath
        day_paths = []; month_paths = []; year_paths = []
        event_page.begin_event_date.upto(event_page.end_event_date) do |d|
          day_paths   << "#{event_top_path}/#{d.year}/#{d.month}/#{d.day}.html"
          month_paths << "#{event_top_path}/#{d.year}/#{d.month}/"
          year_paths  << "#{event_top_path}/#{d.year}/"
        end
        day_paths.uniq!; month_paths.uniq!; year_paths.uniq!

        allow_any_instance_of(::EventCalendar::Susanoo::Exports::XmlCreator).to receive(:rsync).and_return(true)

        actual_index_page_paths = []
        allow(::Susanoo::Exports::PageCreator).to receive(:new) do |path|
          actual_index_page_paths << path
          double("::Susanoo::Exports::PageCreator @paht=#{path}").as_null_object.tap do |o|
            case path
            when *year_paths   # 年
              expect(o).to     receive(:make).with(no_args).once
              expect(o).to_not receive(:delete)
            when *month_paths  # 月
              expect(o).to     receive(:make).with(no_args).once
              expect(o).to_not receive(:delete)
            when *day_paths    # 日
              expect(o).to     receive(:make).with(no_args).once
              expect(o).to_not receive(:delete)
            end
          end
        end

        export.create_event_page(event_page.id)

        expect(actual_index_page_paths).to match_array(day_paths + month_paths + year_paths + year_paths)
      end
    end


    describe "#cancel_event_page" do
      let(:event_top) { create(:genre, event_folder_type: ::Genre.event_folder_types[:top])}
      let(:event_page) { create(:page, genre_id: event_top.id, begin_event_date: Date.new(2013, 11, 25), end_event_date: Date.new(2013, 12, 5)) }

      before do
        allow_any_instance_of(::Susanoo::Exports::PageCreator).to receive(:make).and_return(true)
        allow_any_instance_of(::Susanoo::Exports::PageCreator).to receive(:delete)
      end

      it "XmlCreatorでxmlをmakeしていること" do
        expect_any_instance_of(::EventCalendar::Susanoo::Exports::XmlCreator).to receive(:make)
        export.cancel_event_page(event_page.id)
      end

      it "::Susanoo::Exports::PageCreator でページをmakeしていること" do
        event_top_path = Pathname(event_top.path).cleanpath
        day_paths = []; month_paths = []; year_paths = []
        event_page.begin_event_date.upto(event_page.end_event_date) do |d|
          day_paths   << "#{event_top_path}/#{d.year}/#{d.month}/#{d.day}.html"
          month_paths << "#{event_top_path}/#{d.year}/#{d.month}/"
          year_paths  << "#{event_top_path}/#{d.year}/"
        end
        day_paths.uniq!; month_paths.uniq!; year_paths.uniq!

        allow_any_instance_of(::EventCalendar::Susanoo::Exports::XmlCreator).to receive(:rsync).and_return(true)

        actual_index_page_paths = []
        allow(::Susanoo::Exports::PageCreator).to receive(:new) do |path|
          actual_index_page_paths << path
          double("::Susanoo::Exports::PageCreator @paht=#{path}").as_null_object.tap do |o|
            case path
            when *year_paths   # 年
              expect(o).to     receive(:make).with(no_args).once
              expect(o).to_not receive(:delete)
            when *month_paths  # 月
              expect(o).to     receive(:make).with(no_args).once
              expect(o).to_not receive(:delete)
            when *day_paths    # 日
              expect(o).to_not receive(:make)
              expect(o).to     receive(:delete).with(no_args).once
            end
          end
        end

        export.cancel_event_page(event_page.id)

        expect(actual_index_page_paths).to match_array(day_paths + month_paths + year_paths + year_paths)
      end
    end

    describe "#update_event_page_title" do

      let(:event_top) { create(:genre, event_folder_type: ::Genre.event_folder_types[:top])}
      let(:event_page) { create(:page, genre_id: event_top.id, begin_event_date: Date.new(2013, 11, 25), end_event_date: Date.new(2013, 12, 5)) }

      it "EventPageIndexCreatorでページをmakeしていること" do
        allow_any_instance_of(::EventCalendar::Susanoo::Exports::XmlCreator).to receive(:rsync).and_return(true)
        export.update_event_page_title(event_top.id)
      end
    end
  end
end
