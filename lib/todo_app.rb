# encoding: UTF-8
# frozen_string_literal: true

require_relative 'storage'
require_relative 'task'
require_relative 'history'

# TodoApp 클래스: 애플리케이션의 핵심 로직
class TodoApp
  attr_reader :tasks

  def initialize(storage, data_dir = nil)
    @storage = storage
    @data_dir = data_dir || Dir.home
    @history = History.new(@data_dir)
    @tasks = @storage.load_tasks
    # ID 재할당 (데이터 로드 후 ID 정리)
    @tasks.each_with_index { |task, idx| task.id = idx }
    # 앱 시작 시 완료되지 않은 작업이 먼저 표시되도록 정렬
    sort_tasks_without_save
    # 초기 상태 기록
    @history.record_action('init', @tasks)
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
    @history.record_action('add', @tasks)

    task
  end

  # 할일 삭제
  def delete_task(index)
    return if index < 0 || index >= @tasks.size

    @history.record_action('delete', @tasks)
    @tasks.delete_at(index)
    # ID 재할당
    @tasks.each_with_index { |task, idx| task.id = idx }
    save_tasks
  end

  # 할일 완료/미완료 토글
  def toggle_task(index)
    return if index < 0 || index >= @tasks.size

    @history.record_action('toggle', @tasks)
    @tasks[index].completed = !@tasks[index].completed
    save_tasks
  end

  # 작업 순서 변경 - 위로 이동
  def move_task_up(index)
    return false if index <= 0 || index >= @tasks.size

    @history.record_action('move_up', @tasks)
    @tasks[index], @tasks[index - 1] = @tasks[index - 1], @tasks[index]
    # ID 재할당
    @tasks.each_with_index { |task, idx| task.id = idx }
    save_tasks
    true
  end

  # 작업 순서 변경 - 아래로 이동
  def move_task_down(index)
    return false if index < 0 || index >= @tasks.size - 1

    @history.record_action('move_down', @tasks)
    @tasks[index], @tasks[index + 1] = @tasks[index + 1], @tasks[index]
    # ID 재할당
    @tasks.each_with_index { |task, idx| task.id = idx }
    save_tasks
    true
  end

  # 작업 편집
  def edit_task(index, new_title)
    return if index < 0 || index >= @tasks.size || new_title.nil? || new_title.strip.empty?

    @history.record_action('edit', @tasks)
    @tasks[index].title = new_title
    save_tasks
  end

  # 작업 취소 (undo)
  def undo
    previous_tasks = @history.undo
    return false if previous_tasks.nil?

    @tasks = previous_tasks
    save_tasks
    true
  end

  # 작업 다시 실행 (redo)
  def redo
    next_tasks = @history.redo
    return false if next_tasks.nil?

    @tasks = next_tasks
    save_tasks
    true
  end

  private

  # 할일 저장
  def save_tasks
    @storage.save_tasks(@tasks)
  end

  # 완료되지 않은 작업이 위로 오도록 정렬 (저장하지 않음)
  def sort_tasks_without_save
    @tasks.sort_by! { |task| task.completed ? 1 : 0 }
    # ID 재할당
    @tasks.each_with_index { |task, idx| task.id = idx }
  end
end
