# encoding: UTF-8
# frozen_string_literal: true

# Task 클래스: 할일 항목을 표현
class Task
  attr_accessor :id, :title, :completed

  def initialize(id: nil, title: '', completed: false)
    @id = id
    @title = title
    @completed = completed
  end

  # 마크다운 체크박스 형식으로 문자열 반환
  def to_markdown
    checkbox = @completed ? '[x]' : '[ ]'
    "- #{checkbox} #{@title}"
  end

  # 마크다운 문자열에서 Task 객체 생성
  def self.from_markdown(line, id)
    if line =~ /- \[(x| )\] (.+?)$/
      completed = $1 == 'x'
      title = $2

      Task.new(
        id: id,
        title: title,
        completed: completed
      )
    else
      nil
    end
  end
end
