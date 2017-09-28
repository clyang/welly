#!/bin/bash
# 获取参数
# 检查参数个数
ArgsNum=$#
if [ $ArgsNum != 1 ]
then
	echo "Usage:   $0 <Nib File Name (w/o .nib)>"
	echo "Example: $0 MainMenu"
	exit 1
fi
NibFileName=$1

# 1. 将中文nib备份一份，以供ibtool使用。
cd zh_CN.lproj
cp -rp $NibFileName.nib $NibFileName.old.nib

# 2. 将zh_TW和English的对应文件改名
cd ../English.lproj
mv $NibFileName.nib $NibFileName.old.nib
cd ../zh_TW.lproj
mv $NibFileName.nib $NibFileName.old.nib

# 3. 使用IB修改zh_CN.lproj/MainMenu.nib，只改简体中文的，另两个不要动。
echo "Please use Interface Builder to edit zh_CN.lproj/$NibFileName.nib"
echo "Press enter when finished"
read NotUsed

# 4. 生成string file
cd ../zh_CN.lproj
ibtool --generate-stringsfile $NibFileName.strings $NibFileName.nib

# 5. 复制到zh_TW和English目录中
cp $NibFileName.strings ../English.lproj
cp $NibFileName.strings ../zh_TW.lproj

# 6. 本地化English
# 6.1 编辑strings
cd ../English.lproj
echo "Please localize strings for English locale"
echo "Please delete all the EXISTED items. Just leave the newly added items alone."
echo "If there's no textmate in your system, try some other text editor. "
mate $NibFileName.strings
echo "Press enter to proceed"
read NotUsed

# 6.2 用ibtool生成nib
ibtool --previous-file ../zh_CN.lproj/$NibFileName.old.nib --incremental-file ./$NibFileName.old.nib --strings-file ./$NibFileName.strings --localize-incremental --write ./$NibFileName.nib ../zh_CN.lproj/$NibFileName.nib

# 6.3 修正svn相关文件
rm -rf $NibFileName.nib/.svn
cp -rp $NibFileName.old.nib/.svn $NibFileName.nib/

# 6.4 清理文件
rm $NibFileName.strings
rm -rf $NibFileName.old.nib

# 7. 本地化zh_TW
# 7.1 编辑strings
cd ../zh_TW.lproj
echo "Please localize strings for zh_TW locale"
mate $NibFileName.strings
echo "Press enter to proceed"
read NotUsed

# 7.2 用ibtool生成nib
ibtool  --previous-file ../zh_CN.lproj/$NibFileName.old.nib --incremental-file ./$NibFileName.old.nib --strings-file ./$NibFileName.strings --localize-incremental --write ./$NibFileName.nib ../zh_CN.lproj/$NibFileName.nib

# 7.3 修正svn相关文件
rm -rf $NibFileName.nib/.svn
cp -rp $NibFileName.old.nib/.svn $NibFileName.nib/

# 7.4 清理
rm $NibFileName.strings
rm -rf $NibFileName.old.nib

# 8. 清理
cd ../zh_CN.lproj
rm $NibFileName.strings
rm -rf $NibFileName.old.nib

# 9. 完成
cd ..
echo "Finished!"
