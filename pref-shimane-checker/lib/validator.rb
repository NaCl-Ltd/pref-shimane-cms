require "java"

java_import "jp.netlab.michecker.VisualizeAndCheck"

#
#== michecker の Java クラスを呼び出すためのライブラリ
#
class Validator
    
  #
  #=== アクセシビリティチェックを行う
  #
  def self.exec(html, options={})
    tmp  = File.join(Rails.root.to_s, "tmp", "validate")
    vac  = VisualizeAndCheck.new(tmp.to_s)
    json = vac.doEvaluate(html)
    if json.present?
      return json
    else
      return {}
    end
  end
end
