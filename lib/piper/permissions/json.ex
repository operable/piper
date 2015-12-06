defprotocol Piper.Permissions.Json do

  def to_json!(value)

  def from_json!(value, json)

end
