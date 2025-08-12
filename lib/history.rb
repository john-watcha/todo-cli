# encoding: UTF-8
# frozen_string_literal: true

require 'json'
require 'fileutils'

# History 클래스: Undo/Redo 기능을 위한 작업 기록 관리
class History
  HISTORY_FILE = '.todo_history.json'
  MAX_HISTORY = 100

  def initialize(data_dir)
    @data_dir = data_dir
    @history_path = File.join(@data_dir, HISTORY_FILE)
    @actions = load_history
    @undone_actions = []  # Redo를 위한 작업 기록
  end

  # 작업 상태 저장
  def record_action(action_type, tasks_state)
    # 새 작업이 기록되면 Redo 작업 기록 초기화
    @undone_actions.clear

    # 작업 상태의 딥 카피를 생성
    tasks_snapshot = tasks_state.map do |task|
      {
        id: task.id,
        title: task.title,
        completed: task.completed
      }
    end

    # 작업 기록 저장
    action = {
      type: action_type,
      timestamp: Time.now.to_i,
      tasks: tasks_snapshot
    }

    @actions.push(action)

    # 최대 기록 개수를 초과하면 가장 오래된 기록 삭제
    @actions.shift if @actions.size > MAX_HISTORY

    save_history
  end

  # Undo 실행 - 가장 최근 작업 상태를 반환
  def undo
    # 기록이 없으면 nil 반환
    return nil if @actions.empty?

    # 가장 최근 작업을 Redo 스택으로 이동
    last_action = @actions.pop
    @undone_actions.push(last_action)

    save_history

    # 기록이 남아있으면 이전 상태를 반환, 아니면 빈 배열 반환
    previous_state = @actions.empty? ? [] : @actions.last[:tasks]

    # Task 객체로 변환하여 반환
    tasks_from_snapshot(previous_state)
  end

  # Redo 실행 - 가장 최근에 Undo한 작업을 다시 실행
  def redo
    # Redo할 작업이 없으면 nil 반환
    return nil if @undone_actions.empty?

    # Redo 스택에서 작업을 꺼내 다시 Actions 스택으로 이동
    action_to_redo = @undone_actions.pop
    @actions.push(action_to_redo)

    save_history

    # 현재 상태 반환 (Redo한 작업 이후의 상태)
    tasks_from_snapshot(action_to_redo[:tasks])
  end

  # 현재 히스토리 상태 저장
  private def save_history
    FileUtils.mkdir_p(@data_dir) unless Dir.exist?(@data_dir)

    history_data = {
      actions: @actions,
      undone_actions: @undone_actions
    }

    File.open(@history_path, 'w:UTF-8') do |file|
      file.write(JSON.generate(history_data))
    end
  end

  # 히스토리 파일 불러오기
  private def load_history
    return [] unless File.exist?(@history_path)

    begin
      content = File.read(@history_path, encoding: 'UTF-8')
      data = JSON.parse(content, symbolize_names: true)
      @undone_actions = data[:undone_actions] || []
      data[:actions] || []
    rescue => e
      # 파일 읽기 실패시 빈 배열 반환
      @undone_actions = []
      []
    end
  end

  # 작업 스냅샷을 Task 객체로 변환
  private def tasks_from_snapshot(snapshot)
    snapshot.map do |task_data|
      Task.new(
        id: task_data[:id],
        title: task_data[:title],
        completed: task_data[:completed]
      )
    end
  end
end
