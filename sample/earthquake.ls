require! <[fs cheerio request bluebird ./main]>

pad = (v, len) -> 
  v = "#v"
  "#{(if v.length < len => '0'*(len - v.length) else '')}#v"

crawler = do
  name: "earthquake"
  state: do
    url: \http://scweb.cwb.gov.tw/Page.aspx?ItemId=20&loc=tw&gis=n
    idx: 0
    month: 1
    year: 1995
    end: false
  data: []
  resume: main.resume
  save: main.save
  iterate: -> 
    if @resume => @resume!
    if @state.end => return null
    ret = do
      url: "http://scweb.cwb.gov.tw/Page.aspx?ItemId=20&loc=tw&gis=n"
      method: \POST
      form: ({} <<< @init-params ) <<< do
        "ctl03$ddlYear": @state.year
        "ctl03$ddlMonth": pad(@state.month,2)
    @state.month++
    if @state.month > 12 =>
      now = new Date!
      @state.year++
      @state.month = 1
      if @state.year == (now.getYear! + 1900) and (@state.month > now.getMonth! + 1) => @state.end = true
      else if @state.year > now.getYear! + 1900 => @state.end = true
    ret
  parse: (b, option) ->
    year = option.form.ctl03$ddlYear
    month = option.form.ctl03$ddlMonth
    $ = cheerio.load b
    list = $(".datalist4 tr")
    for idx from 0 til list.length
      item = list[idx]
      tds = $(item).find("td")
      id        = $(tds.0).text!trim!
      date      = $(tds.1).text!trim!
      ret = /(\d+)月(\d+)日(\d+)時(\d+)分/.exec date
      if !ret => continue
      date = new Date("#year #{ret.1}/#{ret.2} #{ret.3}:#{ret.4}")toString!
      lng       = parseFloat($(tds.2).text!trim!)
      lat       = parseFloat($(tds.3).text!trim!)
      depth     = $(tds.4).text!trim!
      magnitude = $(tds.5).text!trim!
      desc   = $(tds.6).text!
      if isNaN(lat) or isNaN(lng) or isNaN(magnitude) => continue
      @data.push {year:year, month:month, id,date,lat,lng,depth,magnitude,desc}
      console.log "#year/#month / #date /// lat: #lat / lng: #lng / mag: #magnitude"
    console.log "now length: #{@data.length}"
    @save!

(params) <- main.init \http://scweb.cwb.gov.tw/Page.aspx?ItemId=20&loc=tw&gis=n .then
crawler.init-params = params
main.fetch crawler
  .then -> fs.write-file-sync \test.json, JSON.stringify(crawler.data)
  .catch -> console.log "failed: #it"
