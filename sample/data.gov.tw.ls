require! <[fs cheerio request bluebird ./main]>

crawler = do
  name: "data.gov.tw-crawler"
  state: do
    url: \http://data.gov.tw
    idx: 0
    end: false
  data: []
  resume: main.resume
  save: main.save
  iterate: -> 
    if @resume => @resume!
    if @state.end => return null
    ret = do
      url: "#{@state.url}/data_list?title=&page=#{@state.idx}"
      method: \GET
    @state.idx++
    ret
  parse: (b) ->
    $ = cheerio.load b
    $("h2 a").each (idx, it) ~> @data.push ($(it) |> -> {name: it.text!, link:it.attr("href")})
    console.log "now length: #{@data.length}"
    @save!

main.fetch crawler
  .then -> fs.write-file-sync \test.json, JSON.stringify(crawler.data)
  .catch -> console.log "failed: #it"
