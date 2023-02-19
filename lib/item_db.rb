require 'yaml'

module ItemDB
  def self.id2name id
    @@ids2names ||= YAML::load_file("data/items/ids2names.yml")
    @@ids2names[id]
  end

  def self.name2id name
    @@names2ids ||= YAML::load_file("data/items/names2ids.yml")
    @@names2ids[name]
  end
end
