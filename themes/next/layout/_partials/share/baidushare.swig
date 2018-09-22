{% if theme.baidushare.type === "button" %}
<div class="bdsharebuttonbox">
<a href="#" class="bds_tsina" data-cmd="tsina" title="分享到新浪微博"></a>
<a href="#" class="bds_weixin" data-cmd="weixin" title="分享到微信"></a>
<a href="#" class="bds_youdao" data-cmd="youdao" title="分享到有道云笔记"></a>
<a href="#" class="bds_evernotecn" data-cmd="evernotecn" title="分享到印象笔记"></a>
<a href="#" class="bds_tqq" data-cmd="tqq" title="分享到腾讯微博"></a>
<a href="#" class="bds_qzone" data-cmd="qzone" title="分享到QQ空间"></a>
<a href="#" class="bds_renren" data-cmd="renren" title="分享到人人网"></a>
<a href="#" class="bds_copy" data-cmd="copy" title="分享到复制网址"></a>
<a href="#" class="bds_more" data-cmd="more"></a>
</div>

<script>window._bd_share_config={"common":{"bdSnsKey":{},"bdText":"","bdMini":"2","bdMiniList":false,"bdPic":"","bdStyle":"0","bdSize":"24"},"share":{},"image":{"viewList":["tsina","weixin","youdao","evernotecn","tqq","qzone","renren","copy"],"viewText":"分享到：","viewSize":"16"},"selectShare":{"bdContainerClass":null,"bdSelectMiniList":["tsina","weixin","youdao","evernotecn","tqq","qzone","renren","copy"]}};with(document)0[(getElementsByTagName('head')[0]||body).appendChild(createElement('script')).src='/static/api/js/share.js?v=89860593.js?cdnversion='+~(-new Date()/36e5)];</script>
{% elseif theme.baidushare.type === "slide" %}
  <script>
    window._bd_share_config = {
      "common": {
        "bdText": "",
        "bdMini": "1",
        "bdMiniList": false,
        "bdPic": ""
      },
      "image": {
        "viewList": ["tsina", "douban", "sqq", "qzone", "weixin", "twi", "fbook"],
        "viewText": "分享到：",
        "viewSize": "16"
      },
      "slide": {
        "bdImg": "5",
        "bdPos": "left",
        "bdTop": "100"
      }
    }
  </script>
{% endif %}
