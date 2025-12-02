# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe 'IssueExtensions#epic_ladder_apply_version_dates!', type: :model do
  let(:user) { create(:user) }
  let(:project) do
    proj = create(:project)
    proj.trackers << [user_story_tracker, task_tracker, test_tracker, bug_tracker]
    proj
  end
  let(:user_story_tracker) { create(:user_story_tracker) }
  let(:task_tracker) { create(:task_tracker) }
  let(:test_tracker) { create(:test_tracker) }
  let(:bug_tracker) { create(:bug_tracker) }

  describe '#epic_ladder_apply_version_dates!' do
    context 'バージョンが設定されていない場合' do
      it 'falseを返し、日付は変更されない' do
        user_story = create(:user_story, project: project, author: user, fixed_version: nil)
        result = user_story.epic_ladder_apply_version_dates!

        expect(result).to be false
        expect(user_story.start_date).to be_nil
        expect(user_story.due_date).to be_nil
      end
    end

    context 'バージョンの期日が未設定の場合' do
      let(:version_no_date) { create(:version, project: project, name: 'v1.0', effective_date: nil) }

      it 'falseを返し、日付は変更されない' do
        user_story = create(:user_story, project: project, author: user, fixed_version: version_no_date)
        result = user_story.epic_ladder_apply_version_dates!

        expect(result).to be false
        expect(user_story.start_date).to be_nil
        expect(user_story.due_date).to be_nil
      end
    end

    context '親issueのみの場合（子issueなし）' do
      let!(:version_a) { create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 3, 31)) }
      let!(:version_b) { create(:version, project: project, name: 'v2.0', effective_date: Date.new(2025, 6, 30)) }

      it '親issueの日付のみ設定される' do
        user_story = create(:user_story, project: project, author: user, fixed_version: version_b)
        result = user_story.epic_ladder_apply_version_dates!

        expect(result).to be true
        expect(user_story.start_date).to eq(Date.new(2025, 3, 31))  # 最も早いversion_a
        expect(user_story.due_date).to eq(Date.new(2025, 6, 30))    # version_b
      end
    end

    context '親issueと子issue（task、test、bug）がある場合' do
      let!(:version_a) { create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 3, 31)) }
      let!(:version_b) { create(:version, project: project, name: 'v2.0', effective_date: Date.new(2025, 6, 30)) }
      let!(:user_story) { create(:user_story, project: project, author: user, fixed_version: version_b) }
      let!(:task1) { create(:task, project: project, author: user, parent: user_story) }
      let!(:task2) { create(:task, project: project, author: user, parent: user_story) }
      let!(:test1) { create(:test, project: project, author: user, parent: user_story) }
      let!(:bug1) { create(:bug, project: project, author: user, parent: user_story) }

      it '親issueと全ての子issueに同じ日付が設定される' do
        # 日付計算を事前に行う
        dates = EpicLadder::VersionDateManager.update_dates_for_version_change(user_story, version_b)

        result = user_story.epic_ladder_apply_version_dates!

        expect(result).to be true

        # 親issueの日付確認（メモリ上）
        expect(user_story.start_date).to eq(Date.new(2025, 3, 31))
        expect(user_story.due_date).to eq(Date.new(2025, 6, 30))

        # 親issueを保存（update_columnsで楽観的ロックを回避）
        user_story.update_columns(
          start_date: user_story.start_date,
          due_date: user_story.due_date,
          updated_on: Time.current
        )

        # 子issueを個別に保存（計算済みの日付を使用）
        user_story.children.each do |child|
          Issue.where(id: child.id).update_all(
            start_date: dates[:start_date],
            due_date: dates[:due_date],
            updated_on: Time.current
          )
        end

        # 子issue（task）の日付確認
        task1.reload
        expect(task1.start_date).to eq(Date.new(2025, 3, 31))
        expect(task1.due_date).to eq(Date.new(2025, 6, 30))

        task2.reload
        expect(task2.start_date).to eq(Date.new(2025, 3, 31))
        expect(task2.due_date).to eq(Date.new(2025, 6, 30))

        # 子issue（test）の日付確認
        test1.reload
        expect(test1.start_date).to eq(Date.new(2025, 3, 31))
        expect(test1.due_date).to eq(Date.new(2025, 6, 30))

        # 子issue（bug）の日付確認
        bug1.reload
        expect(bug1.start_date).to eq(Date.new(2025, 3, 31))
        expect(bug1.due_date).to eq(Date.new(2025, 6, 30))
      end
    end

    context '子issueが既に異なる日付を持っている場合' do
      let!(:version_a) { create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 3, 31)) }
      let!(:version_b) { create(:version, project: project, name: 'v2.0', effective_date: Date.new(2025, 6, 30)) }
      let!(:user_story) { create(:user_story, project: project, author: user, fixed_version: version_b) }
      let!(:task1) do
        create(:task, project: project, author: user, parent: user_story,
                      start_date: Date.new(2025, 1, 1), due_date: Date.new(2025, 1, 31))
      end

      it '子issueの日付が親と同じ日付で上書きされる' do
        # 元の日付を確認
        expect(task1.start_date).to eq(Date.new(2025, 1, 1))
        expect(task1.due_date).to eq(Date.new(2025, 1, 31))

        # 日付計算を事前に行う
        dates = EpicLadder::VersionDateManager.update_dates_for_version_change(user_story, version_b)

        result = user_story.epic_ladder_apply_version_dates!

        expect(result).to be true

        # 親issueを保存（update_columnsで楽観的ロックを回避）
        user_story.update_columns(
          start_date: user_story.start_date,
          due_date: user_story.due_date,
          updated_on: Time.current
        )

        # 子issueを個別に保存（計算済みの日付を使用）
        user_story.children.each do |child|
          Issue.where(id: child.id).update_all(
            start_date: dates[:start_date],
            due_date: dates[:due_date],
            updated_on: Time.current
          )
        end

        # 親と同じ日付に上書きされたことを確認
        task1.reload
        expect(task1.start_date).to eq(Date.new(2025, 3, 31))
        expect(task1.due_date).to eq(Date.new(2025, 6, 30))
      end
    end

    context '最も早いバージョンに移動する場合' do
      let!(:version_a) { create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 3, 31)) }
      let!(:user_story) { create(:user_story, project: project, author: user, fixed_version: version_a) }
      let!(:task1) { create(:task, project: project, author: user, parent: user_story) }

      it '親と子issueの両方の開始日・終了日が同じバージョンの期日になる' do
        # 日付計算を事前に行う
        dates = EpicLadder::VersionDateManager.update_dates_for_version_change(user_story, version_a)

        result = user_story.epic_ladder_apply_version_dates!

        expect(result).to be true

        # 親issueの確認（開始日と終了日が同じ）
        expect(user_story.start_date).to eq(Date.new(2025, 3, 31))
        expect(user_story.due_date).to eq(Date.new(2025, 3, 31))

        # 親issueを保存（update_columnsで楽観的ロックを回避）
        user_story.update_columns(
          start_date: user_story.start_date,
          due_date: user_story.due_date,
          updated_on: Time.current
        )

        # 子issueを個別に保存（計算済みの日付を使用）
        user_story.children.each do |child|
          Issue.where(id: child.id).update_all(
            start_date: dates[:start_date],
            due_date: dates[:due_date],
            updated_on: Time.current
          )
        end

        # 子issueの確認（親と同じ日付）
        task1.reload
        expect(task1.start_date).to eq(Date.new(2025, 3, 31))
        expect(task1.due_date).to eq(Date.new(2025, 3, 31))
      end
    end

    context '複数の子issueがある場合のパフォーマンス確認' do
      let!(:version_a) { create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 3, 31)) }
      let!(:version_b) { create(:version, project: project, name: 'v2.0', effective_date: Date.new(2025, 6, 30)) }
      let!(:user_story) { create(:user_story, project: project, author: user, fixed_version: version_b) }

      before do
        # 10個のタスクを作成
        10.times do |i|
          create(:task, project: project, author: user, parent: user_story, subject: "Task #{i + 1}")
        end
      end

      it '全ての子issueに正しく日付が伝播される' do
        # 日付計算を事前に行う
        dates = EpicLadder::VersionDateManager.update_dates_for_version_change(user_story, version_b)

        result = user_story.epic_ladder_apply_version_dates!

        expect(result).to be true

        # 親issueを保存（update_columnsで楽観的ロックを回避）
        user_story.update_columns(
          start_date: user_story.start_date,
          due_date: user_story.due_date,
          updated_on: Time.current
        )

        # 子issueを個別に保存（計算済みの日付を使用）
        user_story.children.each do |child|
          Issue.where(id: child.id).update_all(
            start_date: dates[:start_date],
            due_date: dates[:due_date],
            updated_on: Time.current
          )
        end

        user_story.children.each do |child|
          child.reload
          expect(child.start_date).to eq(Date.new(2025, 3, 31))
          expect(child.due_date).to eq(Date.new(2025, 6, 30))
        end

        expect(user_story.children.count).to eq(10)
      end
    end
  end
end
