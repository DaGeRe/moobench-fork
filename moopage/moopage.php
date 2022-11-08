<?php
/*
Plugin Name: moopage
Description: [moopage url="partial-url"] shortcode
Author: Reiner Jung
*/

if ( !function_exists( 'moopage_embed_shortcode' ) ) {

  function moopage_embed_shortcode($atts) {
    extract(shortcode_atts(array(
      'url' => ''
    ), $atts));
    $url = 'https://maui.se.informatik.uni-kiel.de/repo/moobench/' . $url;
    return file_get_contents($url);
  }
  add_shortcode('moopage', 'moopage_embed_shortcode');
}
?>
