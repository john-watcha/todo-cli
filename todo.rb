#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

# 기본 인코딩을 UTF-8로 설정
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Bundler를 사용하여 gem 의존성 관리
require 'bundler/setup'
Bundler.require

require_relative 'lib/todo_app'
require_relative 'lib/ui'

# 앱 실행에 필요한 gem 설치 확인
begin
  require 'curses'
rescue LoadError
  puts "필요한 gem이 설치되어 있지 않습니다. 설치하려면 다음 명령어를 실행하세요:"
  puts "bundle install"
  exit 1
end

# 기본 데이터 디렉토리 및 파일 경로 설정
DATA_DIR = File.join(Dir.home, '.todo-cli')
TASKS_FILE = File.join(DATA_DIR, 'tasks.md')

# 데이터 디렉토리가 없으면 생성
Dir.mkdir(DATA_DIR) unless Dir.exist?(DATA_DIR)

# 스크립트가 직접 실행된 경우에만 앱을 실행 (라이브러리로 가져올 때는 실행 안 함)
if __FILE__ == $0
  begin
    # 앱 초기화
    storage = Storage.new(TASKS_FILE)
    app = TodoApp.new(storage)
    ui = UI.new(DATA_DIR)  # DATA_DIR 전달

    # 앱 실행
    ui.run(app)
  rescue => e
    # 오류 발생 시 Curses 화면을 닫고 오류 메시지 출력
    Curses.close_screen if defined?(Curses) && Curses.stdscr
    puts "오류가 발생했습니다: #{e.message}"
    puts e.backtrace
  ensure
    # 프로그램 종료 시 Curses 화면 정리
    ui.close if defined?(ui)
  end
end
