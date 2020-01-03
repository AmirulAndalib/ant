local runtime = import_package "ant.imguibase".runtime
runtime.start {
	policy = {
		"ant.render|mesh",
		"ant.serialize|serialize",
		"ant.bullet|collider.capsule",
		"ant.render|render",
		"ant.render|name",
		"ant.render|shadow_cast",
		"ant.render|directional_light",
		"ant.render|ambient_light",
	},
	system = {
		"ant.modelviewer|model_review_system",
		"ant.modelviewer|steering_system",
		"ant.camera_controller|camera_controller_2"
	},
	pipeline = {
		{ name = "init",
			"init",
			"post_init",
		},
		{ name = "update",
			"timer",
			"data_changed",
			{ name = "animation",
				"animation_state",
				"sample_animation_pose",
				"skin_mesh",
			},
			{ name = "sky",
				"update_sun",
				"update_sky",
			},
			"widget",
			{ name = "render",
				"shadow_camera",
				"filter_primitive",
				"make_shadow",
				"debug_shadow",
				"cull",
				"render_commit",
				{ name = "postprocess",
					"bloom",
					"tonemapping",
					"combine_postprocess",
				}
			},
			"camera_control",
			{ name = "ui",
				"ui_start",
				"ui_update",
				"ui_end",
			},
			"end_frame",
			"final",
		}
	}
}
