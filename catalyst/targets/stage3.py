"""
stage3 target, builds upon previous stage2/stage3 tarball
"""
# NOTE: That^^ docstring has influence catalyst-spec(5) man page generation.

from catalyst import log
from catalyst.base.stagebase import StageBase


class stage3(StageBase):
	"""
	Builder class for a stage3 installation tarball build.
	"""
	def __init__(self,spec,addlargs):
		self.required_values=[]
		self.valid_values=[]
		self.valid_values.extend(["update_stage_command"])
		StageBase.__init__(self,spec,addlargs)

	def set_portage_overlay(self):
		StageBase.set_portage_overlay(self)
		if "portage_overlay" in self.settings:
			log.warning(
				'Using an overlay for earlier stages could cause build issues.\n'
				"If you break it, you buy it.  Don't complain to us about it.\n"
				"Don't say we did not warn you.")

	def set_action_sequence(self):
		"""Set basic stage1, 2, 3 action sequences"""
		self.settings["action_sequence"] = ["unpack", "unpack_snapshot",
				"setup_confdir", "portage_overlay",
				"base_dirs", "bind", "chroot_setup", "setup_environment",
				"run_local", "update_stage", "preclean", "unbind", "clean"]
		self.set_completion_action_sequences()

	def set_cleanables(self):
		StageBase.set_cleanables(self)
