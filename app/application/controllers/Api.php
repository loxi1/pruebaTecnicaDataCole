<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Api extends CI_Controller {

  public function __construct()
  {
    parent::__construct();
    $this->load->database();
  }

  public function ping_db()
  {
    $ok = $this->db->query("SELECT 1 AS ok")->row_array();
    $this->output->set_content_type('application/json')
      ->set_output(json_encode($ok));
  }

  public function void_request($document_id)
  {
    $request_id = $this->input->get('request_id') ?: uniqid('req_', true);

    $q = $this->db->query("CALL sp_process_void_request(?, ?)", [(int)$document_id, $request_id]);

    if ($q === false) {
      $err = $this->db->error();
      $this->output->set_content_type('application/json')
        ->set_output(json_encode([
          'ok' => false,
          'request_id' => $request_id,
          'db_error' => $err
        ], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES));
      return;
    }

    $data = $q->result_array();
    $q->free_result();

    while ($this->db->conn_id->more_results() && $this->db->conn_id->next_result()) {;}

    $this->output->set_content_type('application/json')
      ->set_output(json_encode([
        'ok' => true,
        'request_id' => $request_id,
        'data' => $data
      ], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES));
  }
}