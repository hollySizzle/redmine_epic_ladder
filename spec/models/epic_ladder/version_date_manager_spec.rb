# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe EpicLadder::VersionDateManager do
  let(:user) { create(:user) }
  let(:tracker) { create(:user_story_tracker) }
  let(:project) do
    proj = create(:project)
    proj.trackers << tracker unless proj.trackers.include?(tracker)
    proj
  end
  let(:issue) do
    create(:user_story, project: project, author: user)
  end

  describe '.update_dates_for_version_change' do
    context 'バージョンがnilの場合' do
      it 'nilを返す' do
        result = described_class.update_dates_for_version_change(issue, nil)
        expect(result).to be_nil
      end
    end

    context 'バージョンの期日が未設定の場合' do
      let(:version) { create(:version, project: project, effective_date: nil) }

      it 'nilを返す' do
        result = described_class.update_dates_for_version_change(issue, version)
        expect(result).to be_nil
      end
    end

    context '新バージョンより早いバージョンが存在しない場合' do
      let!(:version_a) { create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 10, 10)) }

      it '開始日と終了日の両方が新バージョンの期日になる' do
        result = described_class.update_dates_for_version_change(issue, version_a)

        expect(result[:start_date]).to eq(Date.new(2025, 10, 10))
        expect(result[:due_date]).to eq(Date.new(2025, 10, 10))
      end
    end

    context '新バージョンより早いバージョンが存在する場合' do
      let!(:version_a) { create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 10, 5)) }
      let!(:version_b) { create(:version, project: project, name: 'v1.1', effective_date: Date.new(2025, 10, 10)) }
      let!(:version_c) { create(:version, project: project, name: 'v1.2', effective_date: Date.new(2025, 10, 15)) }

      context 'バージョンBに移動する場合' do
        it '開始日が直前のバージョンAの期日、終了日がバージョンBの期日になる' do
          result = described_class.update_dates_for_version_change(issue, version_b)

          expect(result[:start_date]).to eq(Date.new(2025, 10, 5))  # version_a（直前のバージョン）
          expect(result[:due_date]).to eq(Date.new(2025, 10, 10))   # version_b
        end
      end

      context 'バージョンCに移動する場合' do
        it '開始日が直前のバージョンBの期日、終了日がバージョンCの期日になる' do
          result = described_class.update_dates_for_version_change(issue, version_c)

          expect(result[:start_date]).to eq(Date.new(2025, 10, 10))  # version_b（直前のバージョン）
          expect(result[:due_date]).to eq(Date.new(2025, 10, 15))   # version_c
        end
      end

      context '最も早いバージョンAに移動する場合' do
        it '開始日と終了日の両方がバージョンAの期日になる' do
          result = described_class.update_dates_for_version_change(issue, version_a)

          expect(result[:start_date]).to eq(Date.new(2025, 10, 5))
          expect(result[:due_date]).to eq(Date.new(2025, 10, 5))
        end
      end
    end

    context '期日が未設定のバージョンが混在する場合' do
      let!(:version_a) { create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 10, 5)) }
      let!(:version_b) { create(:version, project: project, name: 'v1.1', effective_date: nil) }
      let!(:version_c) { create(:version, project: project, name: 'v1.2', effective_date: Date.new(2025, 10, 15)) }

      it '期日が未設定のバージョンはスキップされ、直前の期日ありバージョンが開始日になる' do
        result = described_class.update_dates_for_version_change(issue, version_c)

        expect(result[:start_date]).to eq(Date.new(2025, 10, 5))  # version_a（直前の期日ありバージョン、version_bはスキップ）
        expect(result[:due_date]).to eq(Date.new(2025, 10, 15))   # version_c
      end
    end

    context '異なるプロジェクトのバージョンが存在する場合' do
      let(:other_project) { create(:project) }
      let!(:other_version) { create(:version, project: other_project, name: 'other', effective_date: Date.new(2025, 9, 1)) }
      let!(:version_a) { create(:version, project: project, name: 'v1.0', effective_date: Date.new(2025, 10, 10)) }

      it '同じプロジェクトのバージョンのみが対象になる' do
        result = described_class.update_dates_for_version_change(issue, version_a)

        expect(result[:start_date]).to eq(Date.new(2025, 10, 10))
        expect(result[:due_date]).to eq(Date.new(2025, 10, 10))
      end
    end
  end

  describe '.calculate_impact' do
    context '親が存在しない場合' do
      it '自分自身のみがカウントされる' do
        impact = described_class.calculate_impact(issue, update_parent: false)

        expect(impact[:total]).to eq(1)
        expect(impact[:issue_ids]).to eq([issue.id])
        expect(impact[:parent_id]).to be_nil
        expect(impact[:sibling_ids]).to eq([])
      end
    end

    context '親が存在するがupdate_parent=falseの場合' do
      let(:user_story_tracker) { create(:user_story_tracker) }
      let(:task_tracker) { create(:task_tracker) }
      let(:user_story) { create(:user_story, project: project, author: user) }
      let(:task) { create(:task, project: project, parent: user_story, author: user) }

      before do
        project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
        project.trackers << task_tracker unless project.trackers.include?(task_tracker)
      end

      it '自分自身のみがカウントされる' do
        impact = described_class.calculate_impact(task, update_parent: false)

        expect(impact[:total]).to eq(1)
        expect(impact[:issue_ids]).to eq([task.id])
        expect(impact[:parent_id]).to be_nil
        expect(impact[:sibling_ids]).to eq([])
      end
    end

    context '親と兄弟が存在しupdate_parent=trueの場合' do
      let(:user_story_tracker) { create(:user_story_tracker) }
      let(:task_tracker) { create(:task_tracker) }
      let(:bug_tracker) { create(:bug_tracker) }

      let(:user_story) { create(:user_story, project: project, author: user) }
      let(:task1) { create(:task, project: project, parent: user_story, author: user, subject: 'Task1') }
      let(:task2) { create(:task, project: project, parent: user_story, author: user, subject: 'Task2') }
      let(:bug) { create(:bug, project: project, parent: user_story, author: user, subject: 'Bug1') }

      before do
        project.trackers << user_story_tracker unless project.trackers.include?(user_story_tracker)
        project.trackers << task_tracker unless project.trackers.include?(task_tracker)
        project.trackers << bug_tracker unless project.trackers.include?(bug_tracker)
        # 全てのissueを作成
        task1
        task2
        bug
      end

      it '自分+親+兄弟がカウントされる' do
        impact = described_class.calculate_impact(task1, update_parent: true)

        expect(impact[:total]).to eq(4) # task1 + user_story + task2 + bug
        expect(impact[:issue_ids]).to contain_exactly(task1.id, user_story.id, task2.id, bug.id)
        expect(impact[:parent_id]).to eq(user_story.id)
        expect(impact[:sibling_ids]).to contain_exactly(task2.id, bug.id)
      end
    end
  end

  describe '.change_version_with_dates' do
    # NOTE: この共通メソッドの統合テストは spec/controllers/epic_ladder/version_controller_spec.rb で実施
    # ここでは基本的な動作のみを確認
    it 'メソッドが定義されている' do
      expect(described_class).to respond_to(:change_version_with_dates)
    end

    context 'propagate_to_children オプション' do
      let(:user_story_tracker) { create(:user_story_tracker) }
      let(:task_tracker) { create(:task_tracker) }
      let(:bug_tracker) { create(:bug_tracker) }

      let(:project_with_trackers) do
        proj = project
        proj.trackers << user_story_tracker unless proj.trackers.include?(user_story_tracker)
        proj.trackers << task_tracker unless proj.trackers.include?(task_tracker)
        proj.trackers << bug_tracker unless proj.trackers.include?(bug_tracker)
        proj
      end

      let!(:version_a) { create(:version, project: project_with_trackers, name: 'v1.0', effective_date: Date.new(2025, 10, 5)) }
      let!(:version_b) { create(:version, project: project_with_trackers, name: 'v1.1', effective_date: Date.new(2025, 10, 15)) }

      let(:user_story) do
        create(:user_story, project: project_with_trackers, author: user, fixed_version: version_a)
      end
      let!(:task1) do
        create(:task, project: project_with_trackers, parent: user_story, author: user, subject: 'Task1', fixed_version: version_a)
      end
      let!(:task2) do
        create(:task, project: project_with_trackers, parent: user_story, author: user, subject: 'Task2', fixed_version: version_a)
      end
      let!(:bug) do
        create(:bug, project: project_with_trackers, parent: user_story, author: user, subject: 'Bug1', fixed_version: version_a)
      end

      before do
        User.current = user
      end

      context 'propagate_to_children: false（デフォルト）の場合' do
        it '子Issueは変更されない' do
          result = described_class.change_version_with_dates(user_story, version_b.id)

          expect(result[:children]).to eq([])
          expect(task1.reload.fixed_version_id).to eq(version_a.id)
          expect(task2.reload.fixed_version_id).to eq(version_a.id)
          expect(bug.reload.fixed_version_id).to eq(version_a.id)
        end
      end

      context 'propagate_to_children: true の場合' do
        it '子Issueにバージョンが伝播される' do
          result = described_class.change_version_with_dates(
            user_story,
            version_b.id,
            propagate_to_children: true
          )

          expect(result[:children].map(&:id)).to contain_exactly(task1.id, task2.id, bug.id)
          expect(task1.reload.fixed_version_id).to eq(version_b.id)
          expect(task2.reload.fixed_version_id).to eq(version_b.id)
          expect(bug.reload.fixed_version_id).to eq(version_b.id)
        end

        it '子Issueに日付も伝播される' do
          described_class.change_version_with_dates(
            user_story,
            version_b.id,
            propagate_to_children: true
          )

          # version_b (10/15) の開始日は version_a (10/5) の期日
          expect(task1.reload.start_date).to eq(Date.new(2025, 10, 5))
          expect(task1.reload.due_date).to eq(Date.new(2025, 10, 15))
        end

        it '既に同じバージョンの子は結果に含まれない' do
          # task1を先にversion_bに変更
          task1.update!(fixed_version: version_b)

          result = described_class.change_version_with_dates(
            user_story,
            version_b.id,
            propagate_to_children: true
          )

          # task1は既に同じバージョンなので結果に含まれない
          expect(result[:children].map(&:id)).to contain_exactly(task2.id, bug.id)
        end
      end

      context '子Issueが存在しない場合' do
        let(:user_story_without_children) do
          create(:user_story, project: project_with_trackers, author: user, fixed_version: version_a)
        end

        it 'childrenは空配列を返す' do
          result = described_class.change_version_with_dates(
            user_story_without_children,
            version_b.id,
            propagate_to_children: true
          )

          expect(result[:children]).to eq([])
        end
      end
    end
  end
end
