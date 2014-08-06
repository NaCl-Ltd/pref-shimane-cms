Susanoo::Export  # この行が無いとうまく拡張できない

#
# Susanoo::Export に move_mp3 ジョブを処理するメソッドを追加
#
class Susanoo::Export

  action_method :move_mp3

  def move_mp3(arg, tmp_id)
    mover = BrowsingSupport::Exports::Mp3Mover.new
    mover.logger = self.logger
    mover.move(arg, tmp_id)
  end

end
