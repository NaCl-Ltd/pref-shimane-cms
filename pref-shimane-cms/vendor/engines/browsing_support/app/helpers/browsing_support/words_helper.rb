# -*- coding: utf-8 -*-
module BrowsingSupport
  module WordsHelper
    QUERY_TEXT_LIST = [
                       ['あ行', 'あ い う え お ぁ ぃ ぅ ぇ ぉ'],
                       ['か行', 'か き く け こ が ぎ ぐ げ ご'],
                       ['さ行', 'さ し す せ そ ざ じ ず ぜ ぞ'],
                       ['た行', 'た ち つ て と だ ぢ づ で ど っ'],
                       ['な行', 'な に ぬ ね の'],
                       ['は行', 'は ひ ふ へ ほ ば び ぶ べ ぼ ぱ ぴ ぷ ぺ ぽ'],
                       ['ま行', 'ま み む め も'],
                       ['や行', 'や ゆ よ ゃ ゅ ょ'],
                       ['ら行', 'ら り る れ ろ'],
                       ['わ行', 'わ ゐ ゑ を ゎ ん'],
                       ['全て', nil],
                      ]

    def public_term_strftime(time)
      time.strftime('%Y年%m月%d日 %H時%M分') rescue ''
    end
  end
end
