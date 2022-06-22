class ModelBase
    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
        data.map { |datum| self.new(datum) }
    end

    def self.find_by_id(id)
        self.all.each { |instance| return instance if instance.id == id }
    end
end