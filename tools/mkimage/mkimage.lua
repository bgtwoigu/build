--
-- Copyright (C) 2013 The Yudatun Open Source Project
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License version 2 as
-- published by the Free Software Foundation
-- #####################################################################


-- Make image output_image_file from input_directory and properties_file.
-- Usage: lua mkimage.lua input_directory properties_file output_image_file

function usage()
   print("Usage:")
   print("  lua mkimage.lua input_directory image_info_file output_image_file")
end

function main(in_dir, image_info_file, out_file)
   local dir, basename = string.match(out_file, "(%g+)/(%g+).img")
   local mount_point = ""
   if basename == "system" then
      mount_point = "system"
   elseif basename == "userdata" then
      mount_point = "data"
   else
      error("error: unknown image file name " .. basename .. ".img")
   end

   local glob_dict = load_glob_dict(image_info_file)
   local prop_dict = load_image_prop(glob_dict, mount_point)

   if build_image(in_dir, prop_dict, out_file) then
      print("Build image " .. out_file .. " successful.")
   else
      error("error: failed to build " .. out_file .. " from " .. in_dir)
   end
end

-- Load "name=value" pairs from filename
function load_glob_dict(image_info_file)
   local d = {}
   local file, err = io.open(image_info_file, "r")
   if file then
      for line in file:lines() do
         local k, v = string.match(line, "(%g+)=(%g+)")
         d[k] = v
      end
      file:close()
   else
      error("cannot open file " .. err)
   end
   return d
end

-- Make an image information from global dictionary.
-- Args:
--   glob_dict: the global dictionary from the build system.
--   mount_point: such as "system", "data" etc.
function load_image_prop(glob_dict, mount_point)
   local d = {}

   -- common properties
   d["extfs_sparse_flag"] = glob_dict["extfs_sparse_flag"]
   d["mkyaffs2_extra_flags"] = glob_dict["mkyaffs2_extra_flags"]
   d["skip_fsck"] = glob_dict["skip_fsck"]
   d["selinux_fc"] = glob_dict["selinux_fc"]
   d["mount_point"] = mount_point
   if mount_point == "system" then
      -- Default: fs_type = ext4, partition_size = 50 MB
      d["fs_type"] = glob_dict["fs_type"] or "ext4"
      d["partition_size"] = glob_dict["system_size"] or "52428800"
   elseif mount_point == "data" then
      -- Default: fs_type = ext4, partition_size = 100 MB
      d["fs_type"] = glob_dict["fs_type"] or "ext4"
      d["partition_size"] = glob_dict["userdata_size"] o "104857600"
   end

   return d
end

-- Build an image to out_file from in_dir with property prop_dict.
-- Args:
--   in_dir: path of input directory.
--   prop_dict: property dictionary.
--   out_file: path of the output image file.
-- Returns:
--   true if the image is built successfully.
function build_image(in_dir, prop_dict, out_file)
   local command = ""
   local run_fsck = false
   if prop_dict["fs_type"] == "yaffs" then
      command = command .. "mkyafffs2image " .. "-f "
      if prop_dict["mkyaffs2_extra_flags"] then
         command = command .. prop_dict["mkyaffs2_extra_flags"] .. " "
      end
   else
      command = command .. "mkuserimg.sh" .. " "
      if prop_dict["extfs_sparse_flag"] then
         command = command .. prop_dict["extfs_sparse_flag"] .. " "
         run_fsck = true
      end
   end
   command = command .. in_dir .. " "
   command = command .. out_file .. " "
   if prop_dict["fs_type"] == "yaffs" then
      if prop_dict["selinux_fc"] then
         command = command .. prop_dict["selinux_fc"] .. " "
      end
      command = command .. prop_dict["mount_point"] .. " "
   else
      command = command .. prop_dict["fs_type"] .. " "
      command = command .. prop_dict["mount_point"] .. " "
      command = command .. prop_dict["partition_size"] .. " "
      if prop_dict["selinux_fc"] then
         command = command .. prop_dict["selinux_fc"] .. " "
      end
   end

   print(command)
   if os.execute(command) ~= true then
      return false
   end

   if run_fsck and prop_dict["skip_fsck"] ~= "true" then
      -- Inflate the sparse image
      local dir, basename = string.match(out_file, "(%g+)/(%g+).img")
      local unsparse_image = dir .. "/unsparse_" .. basename .. ".img"
      local inflate_command = "simg2img " .. out_file .. " " .. unsparse_image

      print(inflate_command)
      if os.execute(inflate_command) ~= true then
         os.execute("rm -rf " .. unsparse_image)
         return false
      end

      -- Run e2fsck on the inflated image file
      e2fsck_command = "e2fsck " .. "-f -n " .. unsparse_image
      print(e2fsck_command)
      if os.execute(e2fsck_command) ~= true then
         os.execute("rm -rf " .. unsparse_image)
         return false
      end
      os.execute("rm -rf " .. unsparse_image)
   end

   return true
end

-- entry point
if #arg == 3 then
   main(arg[1], arg[2], arg[3])
else
   usage()
   return
end
