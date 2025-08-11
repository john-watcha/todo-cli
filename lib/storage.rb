# encoding: UTF-8
# frozen_string_literal: true

require_relative 'task'

# Storage 클래스: 마크다운 파일에 할일 항목 저장 및 불러오기
class Storage
  def initialize(file_path)
    @file_path = file_path
    ensure_file_exists
  end

  # 파일에서 할일 목록 불러오기
  def load_tasks
    tasks = []
    return tasks unless File.exist?(@file_path)

    begin
      # 파일을 바이너리 모드로 읽기
      content = File.open(@file_path, 'rb') { |f| f.read }

      # UTF-8이 아닌 문자 대체
      if content.encoding != Encoding::UTF_8
        content.force_encoding('UTF-8')
        unless content.valid_encoding?
          content = content.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        end
      end

      # 줄 단위로 분리
      lines = content.split("\n")

      id = 0
      lines.each do |line|
        # 빈 줄이나 nil 건너뛰기
        next if line.nil? || line.empty? || line.strip.empty?

        # UTF-8 인코딩 확인 및 수정
        unless line.valid_encoding?
          line = line.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        end

        task = Task.from_markdown(line, id)
        if task
          tasks << task
          id += 1
        end
      end
    rescue => e
      # 모든 예외 처리 (파일 읽기, 인코딩 등)
      # 실패하면 빈 작업 목록 반환
    end

    tasks
  end

  # 할일 목록을 파일에 저장
  def save_tasks(tasks)
    # 인코딩을 명시적으로 지정하여 파일 쓰기
    File.open(@file_path, 'w:UTF-8') do |file|
      tasks.each do |task|
        file.puts(task.to_markdown)
      end
    end
  rescue => e
    # 파일 저장 중 오류 발생 시 무시
  end

  private

  # 필요한 파일과 디렉토리가 없으면 생성
  def ensure_file_exists
    dir = File.dirname(@file_path)
    Dir.mkdir(dir) unless Dir.exist?(dir)

    unless File.exist?(@file_path)
      # 인코딩을 명시적으로 지정하여 파일 생성
      File.open(@file_path, 'w:UTF-8') do |file|
        file.puts("# 할일 목록")
        file.puts("")
      end
    end
  rescue => e
    # 파일 생성 중 오류 발생 시 무시
  end
end
