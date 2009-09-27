#!/bin/bash
# 获取参数
# 检查参数个数
ArgsNum=$#
if [ $ArgsNum != 1 ]
then
	echo "Usage:   $0 <Xib File Name (w/o .xib)>"
	echo "Example: $0 MainMenu"
	exit 1
fi
XibFileName=$1

# 1. 将中文xib备份一份，以供ibtool使用。
cd zh_CN.lproj
cp -rp $XibFileName.xib $XibFileName.old.xib

# 2. 将zh_TW和English的对应文件改名
cd ../English.lproj
mv $XibFileName.xib $XibFileName.old.xib
cd ../zh_TW.lproj
mv $XibFileName.xib $XibFileName.old.xib

# 3. 使用IB修改zh_CN.lproj/MainMenu.xib，只改简体中文的，另两个不要动。
echo "Please use Interface Builder to edit zh_CN.lproj/$XibFileName.xib"
echo "Press enter when finished"
read NotUsed

# 4. 生成string file
cd ../zh_CN.lproj
ibtool --generate-stringsfile $XibFileName.strings $XibFileName.xib

# 5. 复制到zh_TW和English目录中
cp $XibFileName.strings ../English.lproj
cp $XibFileName.strings ../zh_TW.lproj

# 6. 本地化English
# 6.1 编辑strings
cd ../English.lproj
echo "Please localize strings for English locale"
echo "Please delete all the EXISTED items. Just leave the newly added items alone."
echo "If there's no textmate in your system, try some other text editor. "
mate $XibFileName.strings
echo "Press enter to proceed"
read NotUsed

# 6.2 用ibtool生成xib
ibtool --previous-file ../zh_CN.lproj/$XibFileName.old.xib --incremental-file ./$XibFileName.old.xib --strings-file ./$XibFileName.strings --localize-incremental --write ./$XibFileName.xib ../zh_CN.lproj/$XibFileName.xib

# 6.3 修正svn相关文件
#rm -rf $XibFileName.xib/.svn
#cp -rp $XibFileName.old.xib/.svn $XibFileName.xib/

# 6.4 清理文件
rm $XibFileName.strings
rm -rf $XibFileName.old.xib

# 7. 本地化zh_TW
# 7.1 编辑strings
cd ../zh_TW.lproj
echo "Please localize strings for zh_TW locale"
mate $XibFileName.strings
echo "Press enter to proceed"
read NotUsed

# 7.2 用ibtool生成xib
ibtool  --previous-file ../zh_CN.lproj/$XibFileName.old.xib --incremental-file ./$XibFileName.old.xib --strings-file ./$XibFileName.strings --localize-incremental --write ./$XibFileName.xib ../zh_CN.lproj/$XibFileName.xib

# 7.3 修正svn相关文件
#rm -rf $XibFileName.xib/.svn
#cp -rp $XibFileName.old.xib/.svn $XibFileName.xib/

# 7.4 清理
rm $XibFileName.strings
rm -rf $XibFileName.old.xib

# 8. 清理
cd ../zh_CN.lproj
rm $XibFileName.strings
rm -rf $XibFileName.old.xib

# 9. 完成
cd ..
echo "Finished!"
