# encoding: UTF-8
# frozen_string_literal: true

require 'curses'

# UI 클래스: Curses를 사용한 터미널 사용자 인터페이스
class UI
  def initialize
    setup_curses
    @current_index = 0
    @offset = 0
  end

  # Curses 초기 설정
  def setup_curses
    Curses.init_screen
    Curses.start_color
    Curses.cbreak
    Curses.noecho
    Curses.curs_set(0)  # 커서 숨기기
    Curses.stdscr.keypad(true)

    # 색상 쌍 정의
    Curses.init_pair(1, Curses::COLOR_GREEN, Curses::COLOR_BLACK)   # 완료된 작업
    Curses.init_pair(2, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)  # 선택된 항목
    Curses.init_pair(5, Curses::COLOR_WHITE, Curses::COLOR_BLACK)   # 기본
  end

  # 화면 종료
  def close
    Curses.close_screen
  end

  # 메인 UI 루프 실행
  def run(app)
    loop do
      display_tasks(app.tasks)
      display_help

      case Curses.getch
      when Curses::KEY_UP
        move_cursor_up(app.tasks.size)
      when Curses::KEY_DOWN
        move_cursor_down(app.tasks.size)
      when ' '  # 스페이스바: 작업 완료/미완료 토글
        app.toggle_task(@current_index)
      when 'a', 'A'  # 새 작업 추가
        add_task(app)
      when 'd', 'D'  # 작업 삭제
        app.delete_task(@current_index) unless app.tasks.empty?
      when 'e', 'E'  # 작업 편집
        edit_task(app, @current_index) unless app.tasks.empty?
      when 'q', 'Q'  # 종료
        break
      end
    end
  end

  private

  # 할일 목록 화면에 표시
  def display_tasks(tasks)
    Curses.clear
    max_y = Curses.lines - 2

    if tasks.empty?
      Curses.setpos(0, 0)
      Curses.addstr("할일 목록이 비어 있습니다. 'a'를 눌러 새 할일을 추가하세요.")
      return
    end

    # 현재 화면에 보이는 작업 범위 계산
    @offset = 0 if @offset > @current_index
    @offset = @current_index - max_y + 1 if @current_index >= @offset + max_y

    visible_tasks = tasks[@offset, max_y]

    visible_tasks.each_with_index do |task, idx|
      actual_idx = idx + @offset
      is_selected = (actual_idx == @current_index)

      Curses.setpos(idx, 0)

      # 선택된 항목 강조
      Curses.attron(Curses.color_pair(2)) if is_selected

      # 작업 상태에 따른 색상 적용
      if task.completed
        Curses.attron(Curses.color_pair(1)) unless is_selected
        status = "[x]"
      else
        status = "[ ]"
      end

      Curses.addstr("#{status} ")

      title = task.title[0, Curses.cols - 10] # 긴 제목 자르기

      Curses.addstr("#{title}")

      # 색상 초기화
      Curses.attroff(Curses.color_pair(1)) unless is_selected
      Curses.attroff(Curses.color_pair(2)) if is_selected
    end

    Curses.refresh
  end

  # 도움말 표시
  def display_help
    help_text = "↑/↓: 이동 | Space: 완료/미완료 | a: 추가 | e: 편집 | d: 삭제 | q: 종료"
    Curses.setpos(Curses.lines - 1, 0)
    Curses.addstr(help_text)
  end

  # 커서 위로 이동
  def move_cursor_up(tasks_size)
    @current_index = (@current_index - 1) % [tasks_size, 1].max if tasks_size > 0
  end

  # 커서 아래로 이동
  def move_cursor_down(tasks_size)
    @current_index = (@current_index + 1) % [tasks_size, 1].max if tasks_size > 0
  end

  # 새 작업 추가 대화상자
  def add_task(app)
    title = get_string("새 할일 제목: ")
    return if title.nil? || title.empty?

    app.add_task(title)
  end

  # 작업 편집 대화상자
  def edit_task(app, index)
    task = app.tasks[index]
    return unless task

    title = get_string("할일 제목 (#{task.title}): ")
    title = task.title if title.empty?

    app.edit_task(index, title)
  end

  # 문자열 입력 받기
  def get_string(prompt)
    Curses.setpos(Curses.lines - 2, 0)
    Curses.clrtoeol
    Curses.addstr(prompt)
    Curses.echo
    Curses.curs_set(1)

    str = Curses.getstr

    Curses.noecho
    Curses.curs_set(0)
    Curses.setpos(Curses.lines - 2, 0)
    Curses.clrtoeol

    str
  end
end
