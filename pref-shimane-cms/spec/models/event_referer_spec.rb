require 'spec_helper'

describe EventReferer do
  describe "バリデーション" do
  end

  describe "スコープ" do
  end

  describe "メソッド" do
    describe ".has_plugin?" do

      it "event_calendarが設定されている場合、trueが返ること" do
        result = EventReferer.has_plugin?("<%= plugin('event_calendar_calendar', 'aaa', 'bbb') %>")
        expect(result).to be_true
      end

      it "event_pickupが設定されている場合、trueが返ること" do
        result = EventReferer.has_plugin?("<%= plugin('event_calendar_pickup', 'aaa', '123') %>")
        expect(result).to be_true
      end

      it "event_calendar, event_pickupが設定されてない場合、falseが返ること" do
        result = EventReferer.has_plugin?("<%= plugin('xxxxx', 'aaa') %>")
        expect(result).to be_false
      end
    end
  end
end
