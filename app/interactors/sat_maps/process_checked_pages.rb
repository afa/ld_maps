module SatMaps
  class ProcessCheckedPages < BaseInteractor
    option :session, default: -> { Mechanize.new }

    def call
      load_checked_pages.bind { |pages| process_for(pages) }
    end

    def load_checked_pages
      SatMaps::LoadPages.call(&:state_checked)
    end

    def process_for(pages)
      pages.bind { |page|
        [
          Try {
            print '.'
            children = yield load_children(page)
            yield check_count(children)
            yield check_files(page, children)
            yield check_pages(page, children)
            yield forward(page)
          }
            .to_result
            .or { Success(:skipped) }
        ]
      }
        .typed(Try)
        .traverse
    end

    def load_children(page)
      Try {
        Page.where(parent_id: page.pk).all
      }
        .to_result
    end

    def check_count(children)
      return Failure(:no_children) if children.empty?

      Success()
    end

    def check_pages(page, children)
      if page.links.select { |_, v| v.is_a?(Hash) && v.key?('lvl') }.size == children.select(&:state_saved?).size
        Success()
      else
        Failure(:need_same_saved_count)
      end
    end

    def check_files(page, children)
      if page.files.select { |_, v| v.is_a?(Hash) && v.key?('kind') }.size == children.select(&:state_stored?).size
        Success()
      else
        Failure(:need_same_stored_count)
      end
    end

    def forward(page)
      SatMaps::SavePageWithState.call(page, :state_saved!)
    end
  end
end
