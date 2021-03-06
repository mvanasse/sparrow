var Color, Store;
(function(){
  var ms;
  ms = Meteor.subscribe;
  ms("my_offer");
  ms("my_tags");
  ms("my_pictures");
  ms("my_messages");
  ms("my_alerts");
  ms("my_prompts");
  ms("tagsets");
  ms("sorts");
  ms("points");
  ms("all_offers");
  ms("all_tags");
  ms("all_locations");
  ms("all_markets");
  ms("purchases");
  ms("customers");
  return ms("user_data");
})();
Stripe.setPublishableKey("pk_test_xB8tcSbkx4mwjHjxZtSMuZDf");
Stripe.client_id = "ca_131FztgqheXRmq6vudxED4qdTPtZTjNt";
Color = net.brehaut.Color;
Store = Meteor.BrowserStore;
Store.clear = function(){
  var keys, keeps, diffs, i$, len$, diff, results$ = [];
  keys = Object.keys(Store.keys);
  keeps = ["user_loc", "notes", "gray", "current_nouns", "current_sorts", "current_sorts_order", "current_sorts_selector", "current_tags", "current_tagsets"];
  diffs = _.difference(keys, keeps);
  for (i$ = 0, len$ = diffs.length; i$ < len$; ++i$) {
    diff = diffs[i$];
    console.log(diff);
    results$.push(Store.set(diff, null));
  }
  return results$;
};
Store.clearAll = function(){
  var keys, i$, len$, key, results$ = [];
  keys = _.keys(Store.keys);
  for (i$ = 0, len$ = keys.length; i$ < len$; ++i$) {
    key = keys[i$];
    console.log(key);
    results$.push(Store.set(key, null));
  }
  return results$;
};
(function(){
  var eh;
  eh = EventHorizon;
  return eh.on("select_offer", function(){
    return console.log('selected offer');
  });
})();