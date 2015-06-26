apiClient = require '../api/client'
merge = require 'lodash.merge'

class PagedResource
  constructor: (@resourceType, @nextPage, @query) ->
    @lastPage = @nextPage
    @client = apiClient.type(@resourceType)

  getPage: (page) ->
    @client.get(@pagedQuery(page)).then (resources) =>
      @updateMeta(resources[0].getMeta())
      resources

  getNextPage: ->
    console.log(@nextPage)
    if @nextPage? and @nextPage <= @lastPage
      @getPage(@nextPage)
    else
      Promise.resolve([])

  getPrevPage: ->
    if @prevPage?
      @getPage(@prevPage)
    else
      Promise.resolve([])

  updateMeta: ({page_count, next_page, previous_page}) ->
    @nextPage = next_page
    @prevPage = previous_page
    @lastPage = page_count

  pagedQuery: (page) ->
    merge({page}, @query)

module.exports = PagedResource
