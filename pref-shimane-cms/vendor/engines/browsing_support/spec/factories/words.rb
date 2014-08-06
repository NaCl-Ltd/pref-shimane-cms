# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :word, class: Word do
    sequence(:base) do |n|
      ary = %w(０ １ ２ ３ ４ ５ ６ ７ ８ ９)
      str = n.to_s.split(//).map{|i| ary[i.to_i]}.join
      "単語#{str}"
    end
    sequence(:text) do |n|
      ary = %w(ぜろ いち に さん よん ご ろく なな はち きゅう)
      str = n.to_s.split(//).map{|i| ary[i.to_i]}.join
      "たんご#{str}"
    end
    user { create(:user) }
  end
end
