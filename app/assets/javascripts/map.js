/**
 */
var crowdy = crowdy || {};

/**
 * Map
 */
crowdy.map = crowdy.map || function() {
  this.root = {};
  this.dataServer = window.location.protocol + "//" + window.location.host;
  this.panes = {};
  this.heatMapCache = {};
};

crowdy.map.prototype.buildMap = function(options) {
  var mapdiv = document.getElementById("map-canvas");
  var map = new google.maps.Map(mapdiv, options || {});

  var useragent = navigator.userAgent;
  if (useragent.indexOf('iPhone') != -1 || useragent.indexOf('Android') != -1 ) {
    mapdiv.style.width = '90%';
    mapdiv.style.height = '70%';
  } else {
    mapdiv.style.width = '80%';
    mapdiv.style.height = '800px';
  }

  return map;
};

crowdy.map.prototype.init = function(center) {
  var mapOptions = {
    center: center, //new google.maps.LatLng(35.632291, 139.881371), // Tokyo Disney Land
    zoom: 15,
    maxZoom: 15,
    minZoom: 5,
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    zoomControlOptions: {
      style: google.maps.ZoomControlStyle.SMALL
    },
    streetViewControl: false
  };
  var rootMap = this.buildMap(mapOptions);

  var me = this;
  var updateMap = function() {
    var targetURL = me.dataServer + "/events.json";
    var northEast = this.getBounds().getNorthEast();
    var southWest = this.getBounds().getSouthWest();
    var data = {
      lon_r: [ southWest.lng(), northEast.lng() ],
      lat_r: [ southWest.lat(), northEast.lat() ],
    };
    if (me.dataServer != (window.location.protocol + "//" + window.location.host)) {
      $.ajax(targetURL, {
        data: data,
        type: 'GET',
        dataType: "jsonp",
        success: function(data) {
          me.buildHeatMapLayer(data);
        }
      });
    } else {
      $.ajax(targetURL, {
        data: data,
        type: 'GET',
        dataType: "json",
        success: function(data, textStatus, jqXHR) {
          me.buildHeatMapLayer(data);
        },
        error: function(jqXHR, textStatus, errorThrown) {
          alert("Failed to update heat map data! (" + errorThrown + ")");
        }
      });
    }
  };

  google.maps.event.addListenerOnce(rootMap, 'idle', updateMap);
  google.maps.event.addListener(rootMap, 'dragend', updateMap);
  google.maps.event.addListener(rootMap, 'zoom_changed', updateMap);

  this.root = rootMap;
};


/**
 * Layers.
 */
crowdy.map.prototype.buildHeatMapLayer = function(data) {
  if (this.heatMap) {
    this.heatMap.setMap(null);
  }
  var zoom = "" + this.root.getZoom();
  var center = "(" + this.root.getCenter().lat() + "," + this.root.getCenter().lng() + ")";
  var dataSet = [];
  if (this.heatMapCache[zoom] == undefined || this.heatMapCache[zoom][center] == undefined) {
    $(data).each(function(idx, d) {
      dataSet.push({
        location: new google.maps.LatLng(d.lat, d.lon),
        weight:   d.weight
      });
    });
  }

  if (this.heatMapCache[zoom] == undefined) {
    this.heatMapCache[zoom] = {};
  }

  if (this.heatMapCache[zoom][center] == undefined) {
    var heatmap = undefined;
    heatmap = new google.maps.visualization.HeatmapLayer({
      data: dataSet
    });
    var gradient = [
      'rgba(0, 0, 255, 1)',
      'rgba(255, 255, 0, 1)',
      'rgba(255, 255, 0, 1)',
      'rgba(255, 255, 0, 1)',
      'rgba(255, 255, 0, 1)',
      'rgba(255, 255, 0, 1)',
      'rgba(255, 0, 0, 1)'
    ]
    var radiusForScale = { // Rule of thumb: Divide by 2 as the zoom gets stronger.
      15: 5,
      14: 10,
      13: 20,
      12: 30,
      11: 40,
      10: 50,
      9: 60,
      8: 70,
      7: 80,
      6: 900,
      5: 100
    };
    var targetRadius = radiusForScale[this.root.zoom];
    if (targetRadius == undefined && this.root.zoom < 5) { targetRadius = 240 }
    if (targetRadius == undefined && this.root.zoom > 10) { targetRadius = 50 }
    heatmap.setOptions({
      dissipating: true,
      radius: $("#map-canvas").width() / targetRadius,
      gradient: heatmap.get('gradient') ? null : gradient
    });
    this.heatMapCache[zoom][center] = heatmap;
  } else {
    heatmap = this.heatMapCache[zoom][center];
  }
  heatmap.setMap(this.root);
  this.heatMap = heatmap;
};

/**
 * Pane management.
 */
crowdy.map.prototype.registerPane = function(name, position, pane) {
  if (this.panes[name] == undefined) {
    this.panes[name] = pane;
    this.root.controls[position].push(pane);
  }
};

crowdy.map.prototype.deRegisterPane = function(name) {
  delete this.panes[name];
};

crowdy.map.prototype.makeItemizedPane = function(name, contentList, extraClass) {
  var pane = document.createElement("div");
  pane.id = name + "-pane";
  $(pane).addClass("map-pane");
  if (extraClass != undefined) {
    $(pane).addClass(extraClass);
  }
  for (var i = 0; i < contentList.length; i++) {
    var contentDiv = document.createElement("div");
    $(contentDiv).addClass("map-pane-item");
    var itemExtraClass = contentList[i].itemExtraClass;
    if (itemExtraClass) {
      $.each(itemExtraClass, function(i, c) {
        $(contentDiv).addClass(c);
      });
    }
    var content = new crowdy.map.ItemizedPaneItem();
    content.title = contentList[i].title;
    content.action = contentList[i].action;
    var title = document.createElement("div");
    title.innerHTML = content.title;
    var image = document.createElement("img");
    image.src = contentList[i].image;
    var imageSize = contentList[i].imageSize;
    if (imageSize) {
      if (imageSize.width)  { image.width = imageSize.width }
      if (imageSize.height) { image.height = imageSize.height }
    }
    $(image).click(content.action);
    content.image = image;
    var itemExtraAttr = contentList[i].itemExtraAttr;
    if (itemExtraAttr) {
      $.each(itemExtraAttr, function(k, v) {
        $(contentDiv).attr(k, v);
      });
    }
    contentDiv.appendChild(image);
    contentDiv.appendChild(title);
    pane.appendChild(contentDiv);
  }
  return pane;
};

crowdy.map.prototype.makeTextPane = function(name, contentList, extraClass) {
  var pane = document.createElement("div");
  pane.id = name + "-pane";
  $(pane).addClass("map-pane");
  if (extraClass != undefined) {
    $(pane).addClass(extraClass);
  }
  for (var i = 0; i < contentList.length; i++) {
    var contentDiv = document.createElement("div");
    var section = new crowdy.map.TextPaneItem();
    var title = contentList[i].title;
    if (title != undefined) {
      section.title = title;
      var titleDiv = document.createElement("div");
      titleDiv.innerHTML = section.title;
      $(titleDiv).addClass("map-section-title");
      contentDiv.appendChild(titleDiv);
    }
    section.content = contentList[i].content;
    var textDiv = document.createElement("div");
    textDiv.innerHTML = section.content;
    $(textDiv).addClass("map-section-text");
    contentDiv.appendChild(textDiv);
    pane.appendChild(contentDiv);
  }
  return pane;
};

/**
 * Pane Contents.
 */
crowdy.map.ItemizedPaneItem = function() {
  this.image = undefined;
  this.title = "Title";
  this.action = function() {};
};

crowdy.map.TextPaneItem = function() {
  this.title = "Title";
  this.content = "Content";
};

/**
 * Application's map.
 */
$(document).ready(function() {

  if (!window.location.href.match(/.*hazard/)) { return; }

  var map = new crowdy.map;

  /**
   * Use current location if available.
   */
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(function(position) {
      // Set current location only If current location is in available area.
      if (21 < position.coords.latitude && position.coords.latitude < 49
        && 121 < position.coords.longitude && position.coords.longitude < 149) {
        var center = new google.maps.LatLng(
          position.coords.latitude,
          position.coords.longitude
          );
        map.init(center);
        var marker = new google.maps.Marker({
          position: center,
          map: map.root,
          title: "位置精度: " + position.coords.accuracy + " 半径メトル"
        });
      } else {
        alert("There is no satellite data for your location. The app will work only with user-generated data.");
        map.init(new google.maps.LatLng(35.632291, 139.881371));
      }
    });
  } else {
    alert("No support for location information. The app will work only with what is available around Tokyo.");
    map.init(new google.maps.LatLng(35.632291, 139.881371));
  }

  //map.updateMap(map.dataServer, map.root);

  /**
   * Panes.
   */
  var helpSunny = '<font style="color:#FDDD29;font-size:2em">●</font> Best sunlight.';
  var helpMODIS = '<font style="color:rgba(0, 0, 255, 1);font-size:2em">●</font> Very Cloudy<br/>'
    + '<font style="color:rgba(0, 255, 0, 1);font-size:2em">●</font> Cloudy<br/>'
    + '<font style="color:rgba(255, 255, 0, 1);font-size:2em">●</font> Sunny<br/>'
    + '<font style="color:rgba(255, 0, 0, 1);font-size:2em;baseline-shift:sub">●</font> Very Sunny';
/*
  var overlayControlPane = map.makeItemizedPane("overlay", [
      {
        "title": "ON/OFF",
        "action": function() {
          if (map.heatMap == undefined) {
            $.jGrowl("Sorry! The sunchine map is not ready. Please try again in a few seconds.");
            return
          }
          if (map.heatMap.getMap() == undefined || map.heatMap.getMap() == null) {
            $(".map-section-text").parent().parent("div").show();
            map.heatMap.setMap(map.root);
          } else {
            $(".map-section-text").parent().parent("div").hide();
            map.heatMap.setMap(null);
          }
        },
        "image": "images/layer-icon.png",
        "imageSize": { "width": 32 },
        "itemExtraClass": ["map-pane-item-horizontal"],
        "itemExtraAttr": { "data-intro": 'Show and hide the sun map', "data-step": '1', "data-position": "top" }
      },
      {
        "title": "Sunny Places",
        "action": function() {
          $(".map-section-text").html(helpSunny);
          var gradient = [
            'rgba(0, 0, 0, 1)',
            '#FDDD29'
          ]
          map.heatMap.setOptions({ gradient: gradient });
        },
        "image": "images/sunny.png",
        "imageSize": { "width": 32 },
        "itemExtraClass": ["map-pane-item-horizontal"],
        "itemExtraAttr": { "data-intro": helpSunny, "data-step": '2', "data-position": "top" }
      },
      {
        "title": "Modis Full Data",
        "action": function() {
          $(".map-section-text").html(helpMODIS);
          var gradient = [
            'rgba(0, 0, 255, 1)',
            'rgba(0, 255, 0, 1)',
            'rgba(255, 255, 0, 1)',
            'rgba(255, 0, 0, 1)'
          ]
          map.heatMap.setOptions({ gradient: gradient });
        },
        "image": "images/satellite.png",
        "imageSize": { "width": 32 },
        "itemExtraClass": ["map-pane-item-horizontal"],
        "itemExtraAttr": { "data-intro": helpMODIS, "data-step": '3', "data-position": "top" }
      },
      {
        "title": "Help",
        "action": function() {
          introJs().start();
        },
        "image": "images/help.png",
        "imageSize": { "width": 32 },
        "itemExtraClass": ["map-pane-item-horizontal"]
      },
      {
        "title": "Home",
        "action": function() {
          window.location.href = window.location.protocol + "//" + window.location.host;
        },
        "image": "images/home.png",
        "imageSize": { "width": 32 },
        "itemExtraClass": ["map-pane-item-horizontal"]
      },
      {
        "title": "Vote on Twitter?",
        "action": function() {
          window.open("https://twitter.com/intent/tweet?text=I%20vote%20%23cloudlessspots%20for%20%40spaceapps%20People%27s%20Choice%20Award!", "_blank");
        },
        "image": "images/vote.png",
        "imageSize": { "width": 32 },
        "itemExtraClass": ["map-pane-item-horizontal"]
      }
  ], "map-pane-bottom");

  var mapLegendPane = map.makeTextPane("map-legend", [
      {
        "content": helpMODIS
      }
  ], "map-pane-right");
*/
  /**
   * Layout.
   */
  /*
  var config = {
    "panes": [
      {
        "name": "overlay",
        "position": google.maps.ControlPosition.BOTTOM_CENTER,
        "pane": overlayControlPane
      },
      {
        "name": "map-legend",
        "position": google.maps.ControlPosition.RIGHT_CENTER,
        "pane": mapLegendPane
      }
    ]
  };
  $.each(config["panes"], function(key, value) {
    map.registerPane(value["name"], value["position"], value["pane"]);
  });
      */

});

