//
//  main.c
//  nalu_test
//
//  Created by Steve McFarlin on 5/3/12.
//  Copyright (c) 2012 TokBox Inc. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include "h264_stream.h"

uint8_t spsbuff[] = {0x67, 0x4d, 0x0, 0x29, 0xab, 0x41, 0x82, 0x72};

h264_stream_t* h264stream ;

void test_sps() {
    
    read_nal_unit(h264stream, spsbuff, 8);
    debug_nal(h264stream, h264stream->nal);
    
    sps_t *sps = h264stream->sps;
    
    sps->vui_parameters_present_flag = 1;
    sps->vui.aspect_ratio_info_present_flag = 1;
    sps->vui.sar_height = 0;
    sps->vui.sar_width = 0;
    sps->vui.video_signal_type_present_flag = 1;
    sps->vui.video_format = 2;
    sps->vui.timing_info_present_flag = 0;
    sps->vui.num_units_in_tick = 642857;
    sps->vui.time_scale = 18000000;
    sps->vui.fixed_frame_rate_flag = 1;
    sps->vui.nal_hrd_parameters_present_flag = 1;
    sps->vui.vcl_hrd_parameters_present_flag = 1;
    sps->vui.low_delay_hrd_flag = 1;
    sps->vui.pic_struct_present_flag = 1;
    sps->vui.bitstream_restriction_flag = 1;
    sps->vui.motion_vectors_over_pic_boundaries_flag = 1;
    sps->vui.max_bytes_per_pic_denom = 2;
    sps->vui.max_bits_per_mb_denom = 1;
    sps->vui.log2_max_mv_length_horizontal = 8;
    sps->vui.log2_max_mv_length_vertical = 8;
    sps->vui.num_reorder_frames = 0;
    sps->vui.max_dec_frame_buffering = 1;
    
    sps->hrd.cpb_cnt_minus1 = 0;
    sps->hrd.bit_rate_scale = 0;
    sps->hrd.cpb_size_scale = 0;
    sps->hrd.initial_cpb_removal_delay_length_minus1 = 31;
    sps->hrd.cpb_removal_delay_length_minus1 = 17;
    sps->hrd.dpb_output_delay_length_minus1 = 17;
    sps->hrd.time_offset_length = 24;
    
    
    printf("\n\n");
    debug_nal(h264stream, h264stream->nal);

}

void test_sei_bp() {
    
    uint8_t *buf = calloc(64,1);
    
    nal_t *nal = h264stream->nal;
    
    nal->nal_ref_idc = 0;
    nal->nal_unit_type = 6;
    
    h264stream->seis = calloc(sizeof(sei_t*), 1);
    h264stream->num_seis = 1;
    h264stream->seis[0] = sei_new();
    h264stream->sei = h264stream->seis[0];
    
    sei_t* sei = h264stream->sei;
    
    sei->payloadType = 0;
    
    sei_type_0 *sei0 = calloc(sizeof(sei_type_0), 1);
    
    sei0->seq_parameter_set_id = h264stream->sps->seq_parameter_set_id;
    sei0->initial_cbp_removal_delay[0] = 37214; //this should be calculated.
    sei0->initial_cbp_removal_delay_offset[0] = 0;
    
    sei->sei_type_struct = sei0;

    int len = write_nal_unit(h264stream, buf, 64);
    
    printf("############## LENGTH : %d ################\n", len);
    debug_nal(h264stream, h264stream->nal);
    
}

void test_sei_pt() {
    uint8_t *buf = calloc(64, 1);
    nal_t *nal = h264stream->nal;
    
    nal->nal_ref_idc = 0;
    nal->nal_unit_type = 6;
    
    h264stream->seis = calloc(sizeof(sei_t*), 1);
    h264stream->num_seis = 1;
    h264stream->seis[0] = sei_new();
    h264stream->sei = h264stream->seis[0];
    
    sei_t* sei = h264stream->sei;
    
    sei->payloadType = 1;
    
    sei_type_1 *sei1 = calloc(sizeof(sei_type_1), 1);
    
    sei1->cpb_removal_delay = 20;
    sei1->dpb_output_delay = 0;
    sei1->NumClockTS = 1;
    sei1->pic_struct = 0;
    sei1->timings = calloc(sizeof(sei_type_1_pic_timing), 1);
    sei1->timings->clock_timestamp_flag = 1;
    sei1->timings->ct_type = 0;
    sei1->timings->nuit_field_based_flag = 1;
    sei1->timings->counting_type = 1;
    sei1->timings->full_timestamp_flag = 0;
    sei1->timings->discontinuity_flag = 0;
    sei1->timings->cnt_dropped_flag = 0;
    sei1->timings->n_frames = 0;
    sei1->timings->seconds_flag = 1;
    sei1->timings->seconds_value = 1;
    sei1->timings->minutes_flag = 1;
    sei1->timings->minutes_value = 1;
    sei1->timings->hours_flag = 0;
    sei1->timings->hours_value = 0;
    sei1->timings->time_offset = 0;
    
    sei->sei_type_struct = sei1;
    
    int len = write_nal_unit(h264stream, buf, 64);
    
    printf("############## LENGTH : %d ################\n", len);
    debug_nal(h264stream, h264stream->nal);
}

int main(int argc, const char * argv[])
{

    // insert code here...
    h264stream = h264_new();
    test_sps();
    //test_sei_bp();
    test_sei_pt();
    
    return 0;
}

