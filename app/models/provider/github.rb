class Provider::Github
  attr_reader :name, :owner, :branch

  def initialize(config = {})
    @name = config[:name] || ENV.fetch("GITHUB_REPO_NAME", "maybe")
    @owner = config[:owner] || ENV.fetch("GITHUB_REPO_OWNER", "maybe-finance")
    @branch = config[:branch] || ENV.fetch("GITHUB_REPO_BRANCH", "main")
  end

  def fetch_latest_upgrade_candidates
    Rails.cache.fetch("latest_github_upgrade_candidates", expires_in: 2.minutes) do
      Rails.logger.info "Fetching latest GitHub upgrade candidates from #{repo} on branch #{branch}..."
      begin
        latest_release = Octokit.releases(repo).first
        latest_version = latest_release ? Semver.from_release_tag(latest_release.tag_name) : Semver.new(Maybe.version)
        latest_commit = Octokit.branch(repo, branch)

        release_info = if latest_release
                        {
                          version: latest_version,
                          url: latest_release.html_url,
                          commit_sha: Octokit.commit(repo, latest_release.tag_name).sha
                        }
        end

        commit_info = {
          version: latest_version,
          commit_sha: latest_commit.commit.sha,
          url: latest_commit.commit.html_url
        }

        {
          release: release_info,
          commit: commit_info
        }
      rescue => e
        Rails.logger.error "Failed to fetch latest GitHub commits: #{e.message}"
        nil
      end
    end
  end

  private
    def repo
      "#{owner}/#{name}"
    end
end
