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
    # 앱 시작 시 완료되지 않은 작업이 먼저 표시되도록 정렬
    sort_tasks_without_save
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

  # 저장하지 않고 정렬만 수행하는 메서드 (초기화에 사용)
  def sort_tasks_without_save
    @tasks.sort_by! { |task| task.completed ? 1 : 0 }
    # ID 재할당
    @tasks.each_with_index { |task, idx| task.id = idx }
  end

  # 할일 위로 이동
  def move_task_up(index)
    return false if index <= 0 || index >= @tasks.size # 첫 아이템이거나 유효하지 않은 인덱스

    # 현재 아이템과 바로 위 아이템 위치 교환
    @tasks[index], @tasks[index-1] = @tasks[index-1], @tasks[index]

    # ID 재할당
    @tasks.each_with_index { |task, idx| task.id = idx }
    save_tasks
    return true
  end

  # 할일 아래로 이동
  def move_task_down(index)
    return false if index < 0 || index >= @tasks.size - 1 # 마지막 아이템이거나 유효하지 않은 인덱스

    # 현재 아이템과 바로 아래 아이템 위치 교환
    @tasks[index], @tasks[index+1] = @tasks[index+1], @tasks[index]

    # ID 재할당
    @tasks.each_with_index { |task, idx| task.id = idx }
    save_tasks
    return true
  end

  private

  # 변경사항 저장
  def save_tasks
    @storage.save_tasks(@tasks)
  end
end
