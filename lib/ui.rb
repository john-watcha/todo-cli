# encoding: UTF-8
# frozen_string_literal: true

require 'curses'

# UI 클래스: Curses를 사용한 터미널 사용자 인터페이스
class UI
  def initialize(data_dir = nil)
    setup_curses
    @current_index = 0
    @offset = 0
    @data_dir = data_dir || Dir.home
  end

  # Curses 초기 설정
  def setup_curses
    Curses.init_screen
    Curses.cbreak
    Curses.noecho
    Curses.curs_set(0)  # 커서 숨기기
    Curses.stdscr.keypad(true)
    # 색상 관련 설정 제거
  end

  # 화면 종료
  def close
    Curses.close_screen
  end

  # 메인 UI 루프 실행
  def run(app)
    loop do
      display_tasks(app.tasks)
      display_help(app.tasks.size)

      # 특수 키 입력 처리 (쉬프트+화살표 등)
      ch = Curses.getch

      case ch
      when Curses::KEY_UP
        move_cursor_up(app.tasks.size)
      when Curses::KEY_DOWN
        move_cursor_down(app.tasks.size)
      when Curses::KEY_SR, 'K' # 쉬프트+업 (KEY_SR은 일부 터미널에서만 작동)
        if !app.tasks.empty? && app.move_task_up(@current_index)
          # 커서도 함께 위로 이동
          move_cursor_up(app.tasks.size)
        end
      when Curses::KEY_SF, 'J' # 쉬프트+다운 (KEY_SF는 일부 터미널에서만 작동)
        if !app.tasks.empty? && app.move_task_down(@current_index)
          # 커서도 함께 아래로 이동
          move_cursor_down(app.tasks.size)
        end
      when ' '  # 스페이스바: 작업 완료/미완료 토글
        app.toggle_task(@current_index)
      when 'a', 'A'  # 새 작업 추가
        add_task(app)
      when 'd', 'D'  # 작업 삭제
        unless app.tasks.empty?
          # 삭제 전에 현재 인덱스 저장
          current_idx = @current_index

          # 아이템 삭제
          app.delete_task(@current_index)

          # 삭제 후 커서 위치 조정
          # 1. 삭제한 위치에 다음 아이템이 있으면 그 위치 유지 (자동으로 다음 아이템이 현재 위치로 이동)
          # 2. 삭제한 위치가 마지막 아이템이었으면 이전 아이템으로 이동
          if app.tasks.empty?
            @current_index = 0  # 모든 아이템이 삭제된 경우
          elsif current_idx >= app.tasks.size
            @current_index = [app.tasks.size - 1, 0].max  # 마지막 아이템 삭제 시 이전 아이템으로
          end
          # 그 외의 경우는 현재 인덱스 유지 (다음 아이템이 자동으로 그 위치로 이동)
        end
      when 'e', 'E'  # 작업 편집
        edit_task(app, @current_index) unless app.tasks.empty?
      when 'q', 'Q'  # 종료
        break
      when 'h', 'H'  # 도움말
        show_help_screen
      when 'Z'  # Shift+Z로 작업 취소
        # undo 기능 실행
        if app.undo
          # UI 상태 업데이트 (커서 위치가 유효한지 확인)
          @current_index = [[@current_index, app.tasks.size - 1].min, 0].max if !app.tasks.empty?
          @current_index = 0 if app.tasks.empty?
        end
      when 'R'  # Shift+R로 작업 다시 실행
        # redo 기능 실행
        if app.redo
          # UI 상태 업데이트 (커서 위치가 유효한지 확인)
          @current_index = [[@current_index, app.tasks.size - 1].min, 0].max if !app.tasks.empty?
          @current_index = 0 if app.tasks.empty?
        end
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

      # 커서 위치를 화살표로 표시 (gutter 영역) - 유니코드 대신 ASCII 문자 사용
      cursor_indicator = is_selected ? "* " : "  "
      Curses.addstr(cursor_indicator)

      # 작업 상태 표시
      status = task.completed ? "[x]" : "[ ]"
      Curses.addstr("#{status} ")

      # 제목 표시 - 완료되지 않은 작업은 볼드체로 표시
      # 터미널 창이 좁을 경우 발생할 수 있는 nil 오류 방지
      max_title_width = [Curses.cols - 12, 1].max  # 최소 1자 이상 표시 보장
      title = task.title.to_s[0, max_title_width]
      title = "" if title.nil?  # nil이 발생하면 빈 문자열로 대체

      # 완료되지 않은 작업(해야 할 일)은 볼드체로 표시
      Curses.attron(Curses::A_BOLD) unless task.completed
      Curses.addstr(title)
      Curses.attroff(Curses::A_BOLD) unless task.completed
    end

    Curses.refresh
  end

  # 도움말 표시
  def display_help(tasks_total = 0)
    help_text = "[↑/↓] Move  [Space] Toggle  [A]dd  [E]dit  [D]elete  [H]elp  [Q]uit"

    # 현재 위치와 전체 작업 수 정보 추가
    position_info = ""
    if tasks_total > 0
      position_info = "[#{@current_index + 1}/#{tasks_total}]"
    end

    # 화면 하단에 전체 라인을 채우는 반전된 메뉴 영역 생성
    Curses.setpos(Curses.lines - 1, 0)
    Curses.clrtoeol  # 라인 지우기

    # 메뉴 영역 반전 효과 적용
    Curses.attron(Curses::A_REVERSE)

    # 좌우 마진 적용 (각각 1칸)
    left_margin = " "
    right_margin = " "

    # 실제 사용 가능한 너비 계산 (좌우 마진 고려)
    available_width = [Curses.cols - 2, 1].max  # 마진을 제외한 사용 가능 너비 (최소 1)

    # 메뉴 텍스트와 위치 정보 사이에 충분한 공간을 확보하기 위한 계산
    if position_info.empty? || available_width <= position_info.length + 4
      # 위치 정보가 없거나 화면이 너무 좁으면 짧은 메뉴 또는 위치 정보만 표시
      if available_width <= position_info.length && !position_info.empty?
        # 화면이 너무 좁으면 위치 정보만 표시 (잘라서)
        content_text = position_info[0, available_width]
      else
        # 가능한 최대 길이로 메뉴 텍스트 표시
        content_text = help_text[0, available_width].to_s.ljust(available_width)
      end
    else
      # 정상적으로 메뉴와 위치 정보 모두 표시
      menu_width = available_width - position_info.length - 2
      if menu_width > 0
        truncated_help = help_text[0, menu_width].to_s
        content_text = truncated_help.ljust(menu_width) + " " + position_info
      else
        content_text = position_info[0, available_width]
      end
    end

    # 마진을 포함한 최종 텍스트 생성
    if Curses.cols <= 2  # 화면이 매우 좁은 경우
      menu_text = content_text[0, Curses.cols]
    else
      menu_text = left_margin + content_text[0, available_width] + right_margin
    end

    # 메뉴 표시
    Curses.addstr(menu_text)

    # 반전 효과 해제
    Curses.attroff(Curses::A_REVERSE)
  end

  # 상세 도움말 화면 표시
  def show_help_screen
    Curses.clear

    # 앱 제목 및 소개
    Curses.setpos(1, 2)
    Curses.addstr("TODO CLI - 마크다운 기반 할일 관리 앱")

    Curses.setpos(3, 2)
    Curses.addstr("이 앱은 마크다운 형식으로 할일을 관리하는 터미널 기반 애플리케이션입니다.")
    Curses.setpos(4, 2)
    Curses.addstr("모든 할일은 마크다운 체크박스 형식으로 저장되며, 텍스트 편집기에서도 편집 가능합니다.")

    # 단축키 설명
    Curses.setpos(6, 2)
    Curses.addstr("== 단축키 ==")

    keys = [
      ["↑/↓", "커서 위/아래 이동"],
      ["Shift+↑/↓ 또는 K/J", "선택된 항목을 위/아래로 이동"],
      ["Space", "할일 완료/미완료 토글"],
      ["A", "새 할일 추가"],
      ["E", "선택한 할일 편집"],
      ["D", "선택한 할일 삭제"],
      ["Shift+Z", "작업 취소 (최대 100개까지)"],
      ["Shift+R", "작업 다시 실행 (최대 100개까지)"],
      ["H", "이 도움말 화면 표시"],
      ["Q", "앱 종료"]
    ]

    keys.each_with_index do |key, idx|
      Curses.setpos(8 + idx, 4)
      Curses.addstr("#{key[0]}".ljust(20))
      Curses.addstr("#{key[1]}")
    end

    # 파일 위치 정보
    Curses.setpos(8 + keys.size + 2, 2)
    Curses.addstr("할일은 #{File.expand_path(@data_dir)} 디렉토리에 저장됩니다.")
    Curses.setpos(8 + keys.size + 3, 2)
    Curses.addstr("작업 기록은 #{File.expand_path(File.join(@data_dir, '.todo_history.json'))}에 저장됩니다.")

    # 닫기 안내
    Curses.setpos(Curses.lines - 3, 2)
    Curses.addstr("ESC 키를 누르면 이전 화면으로 돌아갑니다.")

    Curses.refresh

    # ESC 키 입력 대기
    loop do
      ch = Curses.getch
      break if ch == 27 # ESC 키 코드
    end
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
