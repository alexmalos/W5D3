require "singleton"
require "sqlite3"
require_relative "model_base"

class QuestionsDatabase < SQLite3::Database
    include Singleton

    def initialize
        super('questions.db')
        self.type_translation = true
        self.results_as_hash = true
    end
end

class Question < ModelBase
    attr_accessor :title, :body, :student_id
    attr_reader :id

    def self.find_by_title(title)
        Question.all.each { |instance| return instance if instance.title == title }
    end

    def self.find_by_author_id(author_id)
        Question.all.select { |instance| instance.student_id == author_id }
    end

    def self.most_followed(n)
        QuestionFollow.most_followed_questions(n)
    end

    def self.most_liked(n)
        QuestionLike.most_liked_questions(n)
    end

    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @student_id = options['student_id']
    end

    def save
        if @id
            QuestionsDatabase.instance.execute(<<-SQL, self.title, self.body, self.student_id)
                INSERT INTO
                    questions(title, body, student_id)
                VALUES
                    (?, ?, ?)
            SQL
            @id = QuestionsDatabase.instance.last_insert_row_id
        else
            QuestionsDatabase.instance.execute(<<-SQL, self.title, self.body, self.student_id, @id)
                UPDATE
                    questions
                SET
                    title = ?, body = ?, student_id = ?
                WHERE
                    id = ?
            SQL
        end
    end

    def author
        User.find_by_id(student_id)
    end

    def replies
        Reply.find_by_question_id(id)
    end

    def followers
        QuestionFollow.followers_for_question_id(id)
    end

    def likers
        QuestionLike.likers_for_question_id(id)
    end

    def num_likes
        QuestionLike.num_likes_for_question_id(id)
    end
end

class User < ModelBase
    attr_accessor :fname, :lname
    attr_reader :id

    def self.find_by_name(fname, lname)
        User.all.each { |instance| return instance if instance.fname == fname && instance.lname == lname }
    end

    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end

    def save
        if @id
            QuestionsDatabase.instance.execute(<<-SQL, self.fname, self.lname)
                INSERT INTO
                    users(fname, lname)
                VALUES
                    (?, ?)
            SQL
            @id = QuestionsDatabase.instance.last_insert_row_id
        else
            QuestionsDatabase.instance.execute(<<-SQL, self.fname, self.lname, @id)
                UPDATE
                    users
                SET
                    fname = ?, lname = ?
                WHERE
                    id = ?
            SQL
        end
    end

    def authored_questions
        Question.find_by_author_id(id)
    end

    def authored_replies
        Reply.find_by_user_id(id)
    end

    def followed_questions
        QuestionFollow.followed_questions_for_user_id(id)
    end

    def liked_questions
        QuestionLike.liked_questions_for_user_id(id)
    end

    def average_karma
        num_likes_arr = self.authored_questions.map { |question| question.num_likes }
        num_likes_arr.sum * 1.0 / num_likes_arr.length
    end
end

class QuestionFollow < ModelBase
    attr_accessor :question_id, :student_id
    attr_reader :id

    def self.followers_for_question_id(question_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
            *
        FROM
            question_follows
        JOIN users ON question_follows.student_id = users.id
        WHERE
            ? = question_follows.question_id
        SQL
        data.map { |datum| User.new(datum) }
    end

    def self.followed_questions_for_user_id(user_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT
            *
        FROM
            question_follows
        JOIN questions ON question_follows.question_id = questions.id
        WHERE
            ? = question_follows.student_id
        SQL
        data.map { |datum| Question.new(datum) }
    end

    def self.most_followed_questions(n)
        data = QuestionsDatabase.instance.execute(<<-SQL, n)
        SELECT
            question_follows.question_id
        FROM
            question_follows
        JOIN questions ON question_follows.question_id = questions.id
        GROUP BY
            question_follows.question_id
        ORDER BY
            COUNT(*) DESC
        LIMIT
            ?
        SQL
        data.map { |datum| Question.find_by_id(datum['question_id']) }
    end

    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @student_id = options['student_id']
    end

    def save
        if @id
            QuestionsDatabase.instance.execute(<<-SQL, self.question_id, self.student_id)
                INSERT INTO
                    question_follows(question_id, student_id)
                VALUES
                    (?, ?)
            SQL
            @id = QuestionsDatabase.instance.last_insert_row_id
        else
            QuestionsDatabase.instance.execute(<<-SQL, self.question_id, self.student_id, @id)
                UPDATE
                    question_follows
                SET
                    question_id = ?, student_id = ?
                WHERE
                    id = ?
            SQL
        end
    end
end

class QuestionLike < ModelBase
    attr_accessor :question_id, :student_id
    attr_reader :id

    def self.likers_for_question_id(q_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, q_id)
        SELECT
            *
        FROM
            question_likes
        JOIN users ON question_likes.student_id = users.id
        WHERE
            ? = question_likes.question_id
        SQL
        data.map { |datum| User.new(datum) }
    end

    def self.num_likes_for_question_id(q_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, q_id)
        SELECT
            COUNT(*) AS num_likes
        FROM
            question_likes
        WHERE
            question_id = ?
        SQL
        data.first['num_likes']
    end

    def self.liked_questions_for_user_id(user_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT
            *
        FROM
            question_likes
        JOIN questions ON question_likes.question_id = questions.id
        WHERE
            ? = question_likes.student_id
        SQL
        data.map { |datum| Question.new(datum) }
    end

    def most_liked_questions(n)
        data = QuestionsDatabase.instance.execute(<<-SQL, n)
        SELECT
            question_likes.question_id
        FROM
            question_likes
        JOIN questions ON question_likes.question_id = questions.id
        GROUP BY
            question_likes.question_id
        ORDER BY
            COUNT(*) DESC
        LIMIT
            ?
        SQL
        data.map { |datum| Question.find_by_id(datum['question_id']) }
    end

    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @student_id = options['student_id']
    end

    def save
        if @id
            QuestionsDatabase.instance.execute(<<-SQL, self.question_id, self.student_id)
                INSERT INTO
                    question_likes(question_id, student_id)
                VALUES
                    (?, ?)
                SQL
            @id = QuestionsDatabase.instance.last_insert_row_id
        else
            QuestionsDatabase.instance.execute(<<-SQL, self.question_id, self.student_id, @id)
                UPDATE
                    question_likes
                SET
                    question_id = ?, student_id = ?
                WHERE
                    id = ?
            SQL
        end
    end
end

class Reply < ModelBase
    attr_accessor :question_id, :student_id, :body, :parent_id
    attr_reader :id

    def self.find_by_user_id(user_id)
        Reply.all.select { |instance| instance.student_id == user_id }
    end

    def self.find_by_question_id(question_id)
        Reply.all.select { |instance| instance.question_id == question_id }
    end

    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @body = options['body']
        @student_id = options['student_id']
        @parent_id = options['parent_id']
    end

    def save
        if @id
            QuestionsDatabase.instance.execute(<<-SQL, self.question_id, self.student_id, self.body, self.parent_id)
                INSERT INTO
                    replies(question_id, student_id, body, parent_id)
                VALUES
                    (?, ?, ?, ?)
            SQL
            @id = QuestionsDatabase.instance.last_insert_row_id
        else
            QuestionsDatabase.instance.execute(<<-SQL, self.question_id, self.student_id, self.body, self.parent_id, @id)
                UPDATE
                    replies
                SET
                    question_id = ?, student_id = ?, body = ?, parent_id = ?
                WHERE
                    id = ?
            SQL
        end
    end

    def update
        raise "Reply not in database" if !@id
        
    end

    def author
        User.find_by_id(student_id)
    end

    def question
        Question.find_by_id(question_id)
    end

    def parent_reply
        Reply.find_by_id(parent_id)
    end

    def child_replies
        Reply.all.select { |reply| reply.parent_id == id } 
    end
end