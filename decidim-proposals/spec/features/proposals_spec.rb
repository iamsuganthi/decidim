# frozen_string_literal: true

require "spec_helper"

describe "Proposals", type: :feature do
  include_context "feature"
  let(:manifest_name) { "proposals" }

  let!(:category) { create :category, participatory_process: participatory_process }
  let!(:scope) { create :scope, organization: organization }
  let!(:user) { create :user, :confirmed, organization: organization }

  let(:address) { "Carrer Pare Llaurador 113, baixos, 08224 Terrassa" }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }

  before do
    Geocoder::Lookup::Test.add_stub(
      address,
      [{ "latitude" => latitude, "longitude" => longitude }]
    )
  end

  context "creating a new proposal" do
    context "when the user is logged in" do
      before do
        login_as user, scope: :user
      end

      context "with creation enabled" do
        let!(:feature) do
          create(:proposal_feature,
                 :with_creation_enabled,
                 manifest: manifest,
                 participatory_process: participatory_process)
        end

        context "when process is not related to any scope" do
          before do
            participatory_process.update_attributes(scope: nil)
          end

          it "can be related to a scope" do
            visit_feature
            click_link "New proposal"

            within "form.new_proposal" do
              expect(page).to have_content(/Scope/i)
            end
          end
        end

        context "when process is related to any scope" do
          before do
            participatory_process.update_attributes(scope: scope)
          end

          it "cannot be related to a scope" do
            visit_feature
            click_link "New proposal"

            within "form.new_proposal" do
              expect(page).not_to have_content("Scope")
            end
          end
        end

        it "creates a new proposal" do
          visit_feature

          click_link "New proposal"

          within ".new_proposal" do
            fill_in :proposal_title, with: "Oriol for president"
            fill_in :proposal_body, with: "He will solve everything"
            select category.name["en"], from: :proposal_category_id
            select scope.name, from: :proposal_scope_id

            find("*[type=submit]").click
          end

          expect(page).to have_content("successfully")
          expect(page).to have_content("Oriol for president")
          expect(page).to have_content("He will solve everything")
          expect(page).to have_content(category.name["en"])
          expect(page).to have_content(scope.name)
          expect(page).to have_content(user.name)
        end

        context "when geocoding is enabled", :serves_map do
          let!(:feature) do
            create(:proposal_feature,
                   :with_creation_enabled,
                   :with_geocoding_enabled,
                   manifest: manifest,
                   participatory_process: participatory_process)
          end

          it "creates a new proposal" do
            visit_feature
            click_link "New proposal"

            within ".new_proposal" do
              fill_in :proposal_title, with: "Oriol for president"
              fill_in :proposal_body, with: "He will solve everything"
              fill_in :proposal_address, with: address
              select category.name["en"], from: :proposal_category_id
              select scope.name, from: :proposal_scope_id

              find("*[type=submit]").click
            end

            expect(page).to have_content("successfully")
            expect(page).to have_content("Oriol for president")
            expect(page).to have_content("He will solve everything")
            expect(page).to have_content(address)
            expect(page).to have_content(category.name["en"])
            expect(page).to have_content(scope.name)
            expect(page).to have_content(user.name)
          end
        end

        context "when the user has verified organizations" do
          let(:user_group) { create(:user_group, :verified) }

          before do
            create(:user_group_membership, user: user, user_group: user_group)
          end

          it "creates a new proposal as a user group" do
            visit_feature
            click_link "New proposal"

            within ".new_proposal" do
              fill_in :proposal_title, with: "Oriol for president"
              fill_in :proposal_body, with: "He will solve everything"
              select category.name["en"], from: :proposal_category_id
              select scope.name, from: :proposal_scope_id
              select user_group.name, from: :proposal_user_group_id

              find("*[type=submit]").click
            end

            expect(page).to have_content("successfully")
            expect(page).to have_content("Oriol for president")
            expect(page).to have_content("He will solve everything")
            expect(page).to have_content(category.name["en"])
            expect(page).to have_content(scope.name)
            expect(page).to have_content(user_group.name)
          end

          context "when geocoding is enabled", :serves_map do
            let!(:feature) do
              create(:proposal_feature,
                     :with_creation_enabled,
                     :with_geocoding_enabled,
                     manifest: manifest,
                     participatory_process: participatory_process)
            end

            it "creates a new proposal as a user group" do
              visit_feature
              click_link "New proposal"

              within ".new_proposal" do
                fill_in :proposal_title, with: "Oriol for president"
                fill_in :proposal_body, with: "He will solve everything"
                fill_in :proposal_address, with: address
                select category.name["en"], from: :proposal_category_id
                select scope.name, from: :proposal_scope_id
                select user_group.name, from: :proposal_user_group_id

                find("*[type=submit]").click
              end

              expect(page).to have_content("successfully")
              expect(page).to have_content("Oriol for president")
              expect(page).to have_content("He will solve everything")
              expect(page).to have_content(address)
              expect(page).to have_content(category.name["en"])
              expect(page).to have_content(scope.name)
              expect(page).to have_content(user_group.name)
            end
          end
        end

        context "when the user isn't authorized" do
          before do
            feature.update_attribute(:permissions, create: { authorization_handler_name: "decidim/dummy_authorization_handler" })
          end

          it "should show a modal dialog" do
            visit_feature
            click_link "New proposal"
            expect(page).to have_content("Authorization required")
          end
        end
      end

      context "when creation is not enabled" do
        it "does not show the creation button" do
          visit_feature
          expect(page).to have_no_link("New proposal")
        end
      end
    end
  end

  context "viewing a single proposal" do
    let!(:feature) do
      create(:proposal_feature,
             manifest: manifest,
             participatory_process: participatory_process)
    end

    let!(:proposals) { create_list(:proposal, 3, feature: feature) }

    it "allows viewing a single proposal" do
      proposal = proposals.first

      visit_feature

      click_link proposal.title

      expect(page).to have_content(proposal.title)
      expect(page).to have_content(proposal.body)
      expect(page).to have_content(proposal.author.name)
      expect(page).to have_content(proposal.reference)
    end

    context "when process is not related to any scope" do
      let!(:proposal) { create(:proposal, feature: feature, scope: scope) }

      before do
        participatory_process.update_attributes(scope: nil)
      end

      it "can be filtered by scope" do
        visit_feature
        click_link proposal.title
        expect(page).to have_content(scope.name)
      end
    end

    context "when process is related to a scope" do
      let!(:proposal) { create(:proposal, feature: feature, scope: scope) }

      before do
        participatory_process.update_attributes(scope: scope)
      end

      it "does not show the scope name" do
        visit_feature
        click_link proposal.title
        expect(page).not_to have_content(scope.name)
      end
    end

    context "when it is an official proposal" do
      let!(:official_proposal) { create(:proposal, feature: feature, author: nil) }

      it "shows the author as official" do
        visit_feature
        click_link official_proposal.title
        expect(page).to have_content("Official proposal")
      end
    end

    context "when a proposal has comments" do
      let(:proposal) { create(:proposal, feature: feature) }
      let(:author) { create(:user, :confirmed, organization: feature.organization) }
      let!(:comments) { create_list(:comment, 3, commentable: proposal) }

      it "shows the comments" do
        visit_feature
        click_link proposal.title

        comments.each do |comment|
          expect(page).to have_content(comment.body)
        end
      end
    end

    context "when a proposal has been linked in a meeting" do
      let(:proposal) { create(:proposal, feature: feature) }
      let(:meeting_feature) do
        create(:feature, manifest_name: :meetings, participatory_process: proposal.feature.participatory_process)
      end
      let(:meeting) { create(:meeting, feature: meeting_feature) }

      before do
        meeting.link_resources([proposal], "proposals_from_meeting")
      end

      it "shows related meetings" do
        visit_feature
        click_link proposal.title

        expect(page).to have_i18n_content(meeting.title)
      end
    end

    context "when a proposal has been linked in a result" do
      let(:proposal) { create(:proposal, feature: feature) }
      let(:result_feature) do
        create(:feature, manifest_name: :results, participatory_process: proposal.feature.participatory_process)
      end
      let(:result) { create(:result, feature: result_feature) }

      before do
        result.link_resources([proposal], "included_proposals")
      end

      it "shows related results" do
        visit_feature
        click_link proposal.title

        expect(page).to have_i18n_content(result.title)
      end
    end

    context "when a proposal has been accepted" do
      let!(:proposal) { create(:proposal, :accepted, feature: feature) }

      it "shows a badge" do
        visit_feature
        click_link proposal.title

        expect(page).to have_content("Accepted")
        expect(page).to have_i18n_content(proposal.answer)
      end
    end

    context "when a proposal has been rejected" do
      let!(:proposal) { create(:proposal, :rejected, feature: feature) }

      it "shows the rejection reason" do
        visit_feature
        click_link proposal.title

        expect(page).to have_content("Rejected")
        expect(page).to have_i18n_content(proposal.answer)
      end
    end

    context "when a proposal has been accepted" do
      let!(:proposal) { create(:proposal, :accepted, feature: feature) }

      it "shows the acceptance reason" do
        visit_feature
        click_link proposal.title

        expect(page).to have_content("Accepted")
        expect(page).to have_i18n_content(proposal.answer)
      end
    end

    context "when the proposals'a author account has been deleted" do
      let(:proposal) { proposals.first }

      before do
        Decidim::DestroyAccount.call(proposal.author, Decidim::DeleteAccountForm.from_params({}))
      end

      it "the user is displayed as a deleted user" do
        visit_feature

        click_link proposal.title

        expect(page).to have_content("Deleted user")
      end
    end
  end

  context "when a proposal has been linked in a project" do
    let(:feature) do
      create(:proposal_feature,
             manifest: manifest,
             participatory_process: participatory_process)
    end
    let(:proposal) { create(:proposal, feature: feature) }
    let(:budget_feature) do
      create(:feature, manifest_name: :budgets, participatory_process: proposal.feature.participatory_process)
    end
    let(:project) { create(:project, feature: budget_feature) }

    before do
      project.link_resources([proposal], "included_proposals")
    end

    it "shows related projects" do
      visit_feature
      click_link proposal.title

      expect(page).to have_i18n_content(project.title)
    end
  end

  context "listing proposals in a participatory process" do
    it "lists all the proposals" do
      create(:proposal_feature,
             manifest: manifest,
             participatory_process: participatory_process)

      create_list(:proposal, 3, feature: feature)

      visit_feature
      expect(page).to have_css(".card--proposal", count: 3)
    end

    context "when voting phase is over" do
      let!(:feature) do
        create(:proposal_feature,
               :with_votes_blocked,
               manifest: manifest,
               participatory_process: participatory_process)
      end

      let!(:most_voted_proposal) do
        proposal = create(:proposal, feature: feature)
        create_list(:proposal_vote, 3, proposal: proposal)
        proposal
      end

      let!(:less_voted_proposal) { create(:proposal, feature: feature) }

      before { visit_feature }

      it "lists the proposals ordered by votes by default" do
        expect(page).to have_selector("a", text: "Most voted")
        expect(page).to have_selector("#proposals .card-grid .column:first-child", text: most_voted_proposal.title)
        expect(page).to have_selector("#proposals .card-grid .column:last-child", text: less_voted_proposal.title)
      end

      it "shows a disabled vote button for each proposal, but no links to full proposals" do
        expect(page).to have_button("Voting disabled", disabled: true, count: 2)
        expect(page).to have_no_link("View proposal")
      end
    end

    context "when voting is disabled" do
      let!(:feature) do
        create(:proposal_feature,
               :with_votes_disabled,
               manifest: manifest,
               participatory_process: participatory_process)
      end

      let!(:lucky_proposal) { create(:proposal, feature: feature) }
      let!(:unlucky_proposal) { create(:proposal, feature: feature) }

      it "lists the proposals ordered randomly" do
        visit_feature

        expect(page).to have_selector("a", text: "Random")
        expect(page).to have_selector("#proposals .card-grid .column", count: 2)
        expect(page).to have_selector("#proposals .card-grid .column", text: lucky_proposal.title)
        expect(page).to have_selector("#proposals .card-grid .column", text: unlucky_proposal.title)
      end

      it "shows only links to full proposals" do
        visit_feature

        expect(page).to have_no_button("Voting disabled", disabled: true)
        expect(page).to have_no_button("Vote")
        expect(page).to have_link("View proposal", count: 2)
      end
    end

    context "when there are a lot of proposals" do
      before do
        create_list(:proposal, 17, feature: feature)
      end

      it "paginates them" do
        visit_feature

        expect(page).to have_css(".card--proposal", count: 12)

        click_link "Next"

        expect(page).to have_selector(".pagination .current", text: "2")

        expect(page).to have_css(".card--proposal", count: 5)
      end
    end

    context "when filtering" do
      context "when official_proposals setting is enabled" do
        before do
          feature.update_attributes(settings: { official_proposals_enabled: true })
        end

        it "can be filtered by origin" do
          visit_feature

          within "form.new_filter" do
            expect(page).to have_content(/Origin/i)
          end
        end

        context "by origin 'official'" do
          it "lists the filtered proposals" do
            create_list(:proposal, 2, :official, feature: feature, scope: scope)
            create(:proposal, feature: feature, scope: scope)
            visit_feature

            within ".filters" do
              choose "Official"
            end

            expect(page).to have_css(".card--proposal", count: 2)
            expect(page).to have_content("2 PROPOSALS")
          end
        end

        context "by origin 'citizenship'" do
          it "lists the filtered proposals" do
            create_list(:proposal, 2, feature: feature, scope: scope)
            create(:proposal, :official, feature: feature, scope: scope)
            visit_feature

            within ".filters" do
              choose "Citizenship"
            end

            expect(page).to have_css(".card--proposal", count: 2)
            expect(page).to have_content("2 PROPOSALS")
          end
        end
      end

      context "when official_proposals setting is not enabled" do
        before do
          feature.update_attributes(settings: { official_proposals_enabled: false })
        end

        it "cannot be filtered by origin" do
          visit_feature

          within "form.new_filter" do
            expect(page).not_to have_content(/Origin/i)
          end
        end
      end

      context "when scoped_proposals setting is enabled" do
        before do
          feature.update_attributes(settings: { scoped_proposals_enabled: true })
        end

        it "cannot be filtered by scope" do
          visit_feature

          within "form.new_filter" do
            expect(page).to have_content(/Scopes/i)
          end
        end
      end

      context "when process is related to a scope" do
        before do
          participatory_process.update_attributes(scope: scope)
        end

        it "cannot be filtered by scope" do
          visit_feature

          within "form.new_filter" do
            expect(page).not_to have_content(/Scopes/i)
          end
        end
      end

      context "when proposal_answering feature setting is enabled" do
        before do
          feature.update_attributes(settings: { proposal_answering_enabled: true })
        end

        context "when proposal_answering step setting is enabled" do
          before do
            feature.update_attributes(
              step_settings: {
                feature.participatory_process.active_step.id => {
                  proposal_answering_enabled: true
                }
              }
            )
          end

          it "can be filtered by state" do
            visit_feature

            within "form.new_filter" do
              expect(page).to have_content(/State/i)
            end
          end

          context "by accepted" do
            it "lists the filtered proposals" do
              create(:proposal, :accepted, feature: feature, scope: scope)
              visit_feature

              within ".filters" do
                choose "Accepted"
              end

              expect(page).to have_css(".card--proposal", count: 1)
              expect(page).to have_content("1 PROPOSAL")

              within ".card--proposal" do
                expect(page).to have_content("Accepted")
              end
            end
          end

          context "by rejected" do
            it "lists the filtered proposals" do
              create(:proposal, :rejected, feature: feature, scope: scope)
              visit_feature

              within ".filters" do
                choose "Rejected"
              end

              expect(page).to have_css(".card--proposal", count: 1)
              expect(page).to have_content("1 PROPOSAL")

              within ".card--proposal" do
                expect(page).to have_content("Rejected")
              end
            end
          end
        end

        context "when proposal_answering step setting is disabled" do
          before do
            feature.update_attributes(
              step_settings: {
                feature.participatory_process.active_step.id => {
                  proposal_answering_enabled: false
                }
              }
            )
          end

          it "cannot be filtered by state" do
            visit_feature

            within "form.new_filter" do
              expect(page).not_to have_content(/State/i)
            end
          end
        end
      end

      context "when proposal_answering feature setting is not enabled" do
        before do
          feature.update_attributes(settings: { proposal_answering_enabled: false })
        end

        it "cannot be filtered by state" do
          visit_feature

          within "form.new_filter" do
            expect(page).not_to have_content(/State/i)
          end
        end
      end

      context "when the user is logged in" do
        before do
          login_as user, scope: :user
        end

        it "can be filtered by category" do
          create_list(:proposal, 3, feature: feature)
          create(:proposal, feature: feature, category: category)

          visit_feature

          within "form.new_filter" do
            select category.name[I18n.locale.to_s], from: "filter_category_id"
          end

          expect(page).to have_css(".card--proposal", count: 1)
        end
      end
    end

    context "when ordering" do
      context "by 'most_voted'" do
        let!(:feature) do
          create(:proposal_feature,
                 :with_votes_enabled,
                 manifest: manifest,
                 participatory_process: participatory_process)
        end

        let!(:most_voted_proposal) do
          proposal = create(:proposal, feature: feature)
          create_list(:proposal_vote, 3, proposal: proposal)
          proposal
        end

        let!(:less_voted_proposal) { create(:proposal, feature: feature) }

        it "lists the proposals ordered by votes" do
          visit_feature

          order_proposals_by("Most voted")

          expect(page).to have_selector("a", text: "Most voted")
          expect(page).to have_selector("#proposals .card-grid .column:first-child", text: most_voted_proposal.title)
          expect(page).to have_selector("#proposals .card-grid .column:last-child", text: less_voted_proposal.title)
        end
      end

      context "by 'most_recent'" do
        let!(:older_proposal) { create(:proposal, feature: feature, created_at: 1.month.ago) }
        let!(:recent_proposal) { create(:proposal, feature: feature) }

        it "lists the proposals ordered by created at" do
          visit_feature

          order_proposals_by("Recent")

          expect(page).to have_selector("a", text: "Recent")
          expect(page).to have_selector("#proposals .card-grid .column:first-child", text: recent_proposal.title)
          expect(page).to have_selector("#proposals .card-grid .column:last-child", text: older_proposal.title)
        end
      end

      context "randomly" do
        let!(:lucky_proposal) { create(:proposal, feature: feature) }
        let!(:unlucky_proposal) { create(:proposal, feature: feature) }

        it "lists the proposals ordered randomly" do
          visit_feature

          order_proposals_by("Random")

          expect(page).to have_selector("a", text: "Random")
          expect(page).to have_selector("#proposals .card-grid .column", count: 2)
          expect(page).to have_selector("#proposals .card-grid .column", text: lucky_proposal.title)
          expect(page).to have_selector("#proposals .card-grid .column", text: unlucky_proposal.title)
        end
      end
    end

    private

    def order_proposals_by(criteria)
      within ".order-by" do
        page.find("ul[data-dropdown-menu$=dropdown-menu] a").click
        click_link criteria
      end
    end
  end
end
