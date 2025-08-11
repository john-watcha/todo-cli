# encoding: UTF-8
# frozen_string_literal: true

require_relative 'storage'
require_relative 'task'

# TodoApp 클래스: 애플리케이션의 핵심 로직
class TodoApp
  attr_reader :tasks

  def initialize(storage)
    @storage = storage
    @tasks = @storage.load_tasks
    # ID 재할당 (데이터 로드 후 ID 정리)
    @tasks.each_with_index { |task, idx| task.id = idx }
  end

  # 새 할일 추가
  def add_task(title)
    id = @tasks.empty? ? 0 : @tasks.last.id + 1
    task = Task.new(
      id: id,
      title: title,
      completed: false
    )

    @tasks << task
    save_tasks

    task
  end

  # 할일 삭제
  def delete_task(index)
    return if index < 0 || index >= @tasks.size

    @tasks.delete_at(index)
    # ID 재할당
    @tasks.each_with_index { |task, idx| task.id = idx }
    save_tasks
  end

  # 할일 완료/미완료 토글
  def toggle_task(index)
    return if index < 0 || index >= @tasks.size

    @tasks[index].completed = !@tasks[index].completed
    save_tasks
  end

  # 할일 편집
  def edit_task(index, title = nil)
    return if index < 0 || index >= @tasks.size

    task = @tasks[index]
    task.title = title if title

    save_tasks
  end

  # 할일 정렬 (미완료 > 완료)
  def sort_tasks
    @tasks.sort_by! { |task| task.completed ? 1 : 0 }

    # ID 재할당
    @tasks.each_with_index { |task, idx| task.id = idx }
    save_tasks
  end

  private

  # 변경사항 저장
  def save_tasks
    @storage.save_tasks(@tasks)
  end
end
