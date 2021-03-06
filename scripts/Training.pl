#!/usr/bin/perl

# Copyright 2011 Matt Shannon
# Copyright 2001-2008 Nagoya Institute of Technology, Department of Computer Science
# Copyright 2001-2008 Tokyo Institute of Technology, Interdisciplinary Graduate School of Science and Engineering

# This file is part of HTS-demo_CMU-ARCTIC-SLT-STRAIGHT-AR-decision-tree.
# See `License` for details of license and warranty.


$|=1;

if (@ARGV<1) {
   print "usage: Training.pl Config.pm\n";
   exit(0);
}

# load configuration variables
require($ARGV[0]);


# File locations =========================
# data directory
$datdir = "$prjdir/data";

# data location file 
$scp{'trn'} = "$datdir/scp/train.scp";
$scp{'tst'} = "$datdir/scp/test.scp";
$scp{'gen'} = "$datdir/scp/gen.scp";

# model list files
$lst{'mon'} = "$datdir/lists/mono.list";
$lst{'ful'} = "$datdir/lists/full.list";
$lst{'all'} = "$datdir/lists/full_all.list";
 
# master label files
$mlf{'mon'} = "$datdir/labels/mono.mlf";
$mlf{'ful'} = "$datdir/labels/full.mlf";
$mlf{'tst'} = "$datdir/labels/test.mlf";

# configuration variable files
$cfg{'trn'} = "$prjdir/configs/trn.cnf";
$cfg{'tst'} = "$prjdir/configs/tst.cnf";
$cfg{'nvf'} = "$prjdir/configs/nvf.cnf";
$cfg{'dump_accs'} = "$prjdir/configs/dump_accs.cnf";
$cfg{'syn'} = "$prjdir/configs/syn.cnf";
$cfg{'gv'}  = "$prjdir/configs/gv.cnf";

# model topology definition file
$prtfile = "$prjdir/proto/ver$ver/";

# model files and accumulator files
foreach $set (@SET){
   $model{$set}   = "$prjdir/models/qst${qnum}/ver${ver}/${set}";
   $hinit{$set}   = "$model{$set}/HInit";
   $hrest{$set}   = "$model{$set}/HRest";
   $vfloors{$set} = "$model{$set}/vFloors";
   $initmmf{$set} = "$model{$set}/init.mmf";
   $monommf{$set} = "$model{$set}/monophone.mmf";
   $fullmmf{$set} = "$model{$set}/fullcontext.mmf";
   $clusmmf{$set} = "$model{$set}/clustered.mmf";
   $untymmf{$set} = "$model{$set}/untied.mmf";
   $reclmmf{$set} = "$model{$set}/re_clustered.mmf";
   $rclammf{$set} = "$model{$set}/re_clustered_all.mmf";
   $tiedlst{$set} = "$model{$set}/tiedlist";
   $gvmmf{$set}   = "$model{$set}/gv.mmf";
   $gvlst{$set}   = "$model{$set}/gv.list";

   $accs{$set}    = "$model{$set}/HER1.$s2ae{$set}";
}

# statistics files
foreach $set (@SET){
   $stats{$set} = "$prjdir/stats/qst${qnum}/ver${ver}/${set}.stats";
}

# model edit files
foreach $set (@SET){
   $hed{$set} = "$prjdir/edfiles/qst${qnum}/ver${ver}/${set}";
   $lvf{$set} = "$hed{$set}/lvf.hed";
   $m2f{$set} = "$hed{$set}/m2f.hed";
   $mku{$set} = "$hed{$set}/mku.hed";
   $unt{$set} = "$hed{$set}/unt.hed";
   $upm{$set} = "$hed{$set}/upm.hed";
   $cxc{$set} = "$hed{$set}/cxc_$set.hed";
}

# questions about contexts
foreach $set (@SET){
   $qs{$set} = "$datdir/questions/questions_qst${qnum}.hed";
}

# decision tree files
foreach $set (@SET){
   $trd{$set} = "${prjdir}/trees/qst${qnum}/ver${ver}/${set}";
   $mdl{$set} = "-m -a $mdlf{$set}" if($applyMdl{$set} eq '1');
   $tre{$set} = "$trd{$set}/${set}.inf";
}

# converted model & tree files for hts_engine
$voice = "$prjdir/voices/qst${qnum}/ver${ver}";
foreach $set (@SET) {
   foreach $type (@{$ref{$set}}) {
      $trv{$type} = "$voice/tree-${type}.inf";
      $pdf{$type} = "$voice/${type}.pdf";
   }
}

# window files for parameter generation
$windir = "${datdir}/win";
foreach $type (@cmp) {
   for ($d=1;$d<=$nwin{$type};$d++) {
      $win{$type}[$d-1] = "${type}.win${d}";
   }
}

# global variance pdf files for parameter generation
$gvdir = "${datdir}/gv";
foreach $type (@cmp) {
   $gvpdf{$type} = "$gvdir/gv-${type}.pdf";
}

# model structure
$vSize{'total'} = 0;
$nstream{'total'} = 0;
$nPdfStreams = 0;
foreach $type (@cmp) {
   $vSize{$type}      = $nwin{$type}*$ordr{$type};
   $vSize{'total'}   += $vSize{$type};
   $nstream{$type}    = $stre{$type}-$strb{$type}+1;
   $nstream{'total'} += $nstream{$type};
   $nPdfStreams++;
}

# HTS Commands & Options ========================
$HCompV         = "$HCOMPV -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'}";
$HInit          = "$HINIT  -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'}                -m 1 -u tmvw    -w $wf";
$HRest          = "$HREST  -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'}                -m 1 -u tmvw    -w $wf";
$HERest{'tst'}  = "$HEREST -A -B -C $cfg{'tst'} -D -T 1 -S $scp{'tst'} -I $mlf{'tst'} -u d ";
$HERest{'mon'}  = "$HEREST -A    -C $cfg{'trn'} -D -T 1 -S $scp{'trn'} -I $mlf{'mon'} -m 1 -u tmvwdmv -w $wf -t $beam ";
$HERest{'ful'}  = "$HEREST -A -B -C $cfg{'trn'} -D -T 1 -S $scp{'trn'} -I $mlf{'ful'} -m 1 -u tmvwdmv -w $wf -t $beam ";
$HHEd{'trn'}    = "$HHED   -A -B -C $cfg{'trn'} -D -T 3 -p -i";
$HMGenS         = "$HMGENS -A -B -C $cfg{'syn'} -D -T 1 -S $scp{'gen'} -t $beam ";

# Initial Values ========================
$minocc = 0.0;

# =============================================================
# ===================== Main Program ==========================
# =============================================================

# make config files
mkdir "$prjdir/configs",0755;
make_config();

# preparing environments
if ($MKEMV) {
   print_time("preparing environments");
   
   # make directories
   foreach $dir ('models', 'stats', 'edfiles', 'trees', 'voices', 'gen') {
      mkdir "$prjdir/$dir", 0755;
      mkdir "$prjdir/$dir/qst${qnum}", 0755;
      mkdir "$prjdir/$dir/qst${qnum}/ver${ver}", 0755;
   }
   foreach $set (@SET) {
      mkdir "$model{$set}", 0755;
      mkdir "$hinit{$set}", 0755;
      mkdir "$hrest{$set}", 0755;
      mkdir "$hed{$set}", 0755;
      mkdir "$trd{$set}", 0755;
   }

   # make model prototype definition file;
   mkdir "$prjdir/proto",0755;
   mkdir "$prjdir/proto/ver$ver",0755;
   make_proto();

   # convert GV pdf -> GV mmf
   if ($useGV) {
      conv_gvpdf2mmf();
   }
}


# HCompV (computing variance floors)
if ($HCMPV) {
   print_time("computing variance floors");
   
   # compute variance floors 
   shell("$HCompV -M $model{cmp} -o $initmmf{'cmp'} $prtfile");
   shell("head -n 1 $prtfile > $initmmf{'cmp'}");
   shell("cat $vfloors{cmp} >> $initmmf{'cmp'}");
}


# HInit & HRest (initialization & reestimation)
if ($IN_RE) {
   print_time("initialization & reestimation");

   open(LIST, $lst{'mon'}) || die "Cannot open $!";
   while ($phone = <LIST>) {
      # trimming leading and following whitespace characters
      $phone =~ s/^\s+//;
      $phone =~ s/\s+$//;

      # skip a blank line
      if ($phone eq '') {
         next;
      }
      $lab = $mlf{'mon'};

      print "=============== $phone ================\n";
      if (grep($_ eq $phone, keys %mdcp) > 0){
         print "use $mdcp{$phone} instead of $phone\n";
         $set = 'cmp';
         open(SRC, "$hrest{$set}/$mdcp{$phone}") || die "Cannot open $!";
         open(TGT, ">$hrest{$set}/$phone") || die "Cannot open $!";
         while (<SRC>){
            s/~h \"$mdcp{$phone}\"/~h \"$phone\"/;
            print TGT;
         }
         close(TGT);
         close(SRC);
      } 
      else {
         shell("$HInit -H $initmmf{'cmp'} -M $hinit{'cmp'} -I $lab -l $phone -o $phone $prtfile");
         shell("$HRest -H $initmmf{'cmp'} -M $hrest{'cmp'} -I $lab -l $phone -g $hrest{'dur'}/$phone $hinit{'cmp'}/$phone");
      }
   }
   close(LIST);
}


# HHEd (making a monophone mmf) 
if ($MMMMF) {
   print_time("making a monophone mmf");

   foreach $set (@SET) {
      open (EDFILE,">$lvf{$set}") || die "Cannot open $!";
      
      # load variance floor macro
      print EDFILE "// load variance flooring macro\n";
      print EDFILE "FV \"$vfloors{$set}\"\n"; 
      
      # tie stream weight macro
      foreach $type (@{$ref{$set}}) {
         if ($strw{$type}!=1.0) {
            print  EDFILE "// tie stream weights\n";
            printf EDFILE "TI SW_all {*.state[%d-%d].weights}\n", 2, $nState+1;
            last;
         }
      }
      
      close(EDFILE);

      shell("$HHEd{'trn'} -d $hrest{$set} -w $monommf{$set} $lvf{$set} $lst{'mon'}");
      shell("gzip -c $monommf{$set} > $monommf{$set}.nonembedded.gz");
   }
}


# HERest (embedded reestimation (monophone))
if ($ERST0) {
   print_time("embedded reestimation (monophone)");
   
   for ($i=1;$i<=($nIte + 1);$i++) {
      # embedded reestimation
      print("\n\nIteration $i of Embedded Re-estimation");
      if ($i == 1) {
         print(" (with cross training for mgc)\n");
         if ($strb{'mgc'} ne $stre{'mgc'}) {
            die "Auto-regressive cross training assumes mgc is only one stream wide\n";
         }
         $crossTrain = "-i $strb{'mgc'} $ordr{'mgc'}";
      }
      elsif ($i == 2) {
         print(" (with cross training for bap)\n");
         if ($strb{'bap'} ne $stre{'bap'}) {
            die "Auto-regressive cross training assumes bap is only one stream wide\n";
         }
         $crossTrain = "-i $strb{'bap'} $ordr{'bap'}";
      }
      else {
         print("\n");
         $crossTrain = "";
      }
      shell("$HERest{'mon'} $crossTrain -H $monommf{'cmp'} -N $monommf{'dur'} -M $model{'cmp'} -R $model{'dur'} $lst{'mon'} $lst{'mon'}");
   }

   # compress reestimated model
   foreach $set (@SET) {
      shell("gzip -c $monommf{$set} > ${monommf{$set}}.embedded.gz");
   }
}


# HHEd (copying monophone mmf to fullcontext one) 
if ($MN2FL) {
   print_time("copying monophone mmf to fullcontext one");

   foreach $set (@SET) {
      open (EDFILE, ">$m2f{$set}") || die "Cannot open $!";
      open (LIST,   "$lst{'mon'}") || die "Cannot open $!";

      print EDFILE "// copy monophone models to fullcontext ones\n";
      print EDFILE "CL \"$lst{'ful'}\"\n\n";    # CLone monophone to fullcontext

      print EDFILE "// tie state transition probability\n";
      while ($phone = <LIST>) {
         # trimming leading and following whitespace characters
         $phone =~ s/^\s+//;
         $phone =~ s/\s+$//;

         # skip a blank line
         if ($phone eq '') {
            next;
         }
         print EDFILE "TI T_${phone} {*-${phone}+*.transP}\n"; # TIe transition prob
      }
            
      close(LIST);
      close(EDFILE);

      shell("$HHEd{'trn'} -H $monommf{$set} -w $fullmmf{$set} $m2f{$set} $lst{'mon'}");
   }
}


# HERest (embedded reestimation (fullcontext))
if ($ERST1) {
   print_time("embedded reestimation (fullcontext)");

   $opt = "-C $cfg{'nvf'} -C $cfg{'dump_accs'} -s $stats{'cmp'} -w 0.0";

   # embedded reestimation   
   print("\n\nEmbedded Re-estimation\n");
   shell("$HERest{'ful'} -H $fullmmf{'cmp'} -N $fullmmf{'dur'} -M $model{'cmp'} -R $model{'dur'} $opt $lst{'ful'} $lst{'ful'}");

   # convert cmp stats to duration ones
   convstats();
}


# HHEd (tree-based context clustering)
if ($CXCL1) {
   print_time("tree-based context clustering");

   foreach $set (@SET) {
      shell("mv $fullmmf{$set} $clusmmf{$set}");

      # tree-based clustering
      $minocc = $mocc{$set};
      make_config();
      make_edfile_state($set, 0);
      shell("$HHEd{'trn'} -H $clusmmf{$set} $mdl{$set} -w $clusmmf{$set} $cxc{$set} $lst{'ful'}");
      shell("rm -f $accs{$set}");
      $footer = "_after";
      shell("gzip -c $clusmmf{$set} > $clusmmf{$set}$footer.gz");
   }
}


# HERest (embedded reestimation (clustered))
if ($ERST2) {
   print_time("embedded reestimation (clustered)");
     
   for ($i=1;$i<$nIte;$i++) {
      print("\n\nIteration $i of Embedded Re-estimation\n");
      shell("$HERest{'ful'} -H $clusmmf{'cmp'} -N $clusmmf{'dur'} -M $model{'cmp'} -R $model{'dur'} $lst{'ful'} $lst{'ful'}");
   }

   # compress reestimated mmfs
   foreach $set (@SET) {
      shell("gzip -c $clusmmf{$set} > $clusmmf{$set}.embedded2.gz");
   }
}


# HHEd (untying the parameter sharing structure)
if ($UNTIE) {
   print_time("untying the parameter sharing structure");

   foreach $set (@SET) {
      make_edfile_untie($set);
      shell("$HHEd{'trn'} -H $clusmmf{$set} -w $untymmf{$set} $unt{$set} $lst{'ful'}");
   }
}


# fix variables
foreach $set (@SET) { 
   $stats{$set} .= ".untied";
   $tre{$set}   .= ".untied";
   $cxc{$set}   .= ".untied";
}


# HERest (embedded reestimation (untied))
if ($ERST3) {
   print_time("embedded reestimation (untied)");

   $opt = "-C $cfg{'nvf'} -C $cfg{'dump_accs'} -s $stats{'cmp'} -w 0.0";

   print("\n\nEmbedded Re-estimation for untied mmfs\n");
   shell("$HERest{'ful'} -H $untymmf{'cmp'} -N $untymmf{'dur'} -M $model{'cmp'} -R $model{'dur'} $opt $lst{'ful'} $lst{'ful'}");

   # convert cmp stats to duration ones
   convstats();
}


# HHEd (tree-based context clustering)
if ($CXCL2) {
   print_time("tree-based context clustering");

   # tree-based clustering
   foreach $set (@SET) {
      shell("mv $untymmf{$set} $reclmmf{$set}");

      $minocc = $mocc{$set};
      make_config();
      make_edfile_state($set, 1);
      shell("$HHEd{'trn'} -H $reclmmf{$set} $mdl{$set} -w $reclmmf{$set} $cxc{$set} $lst{'ful'}");
      shell("rm -f $accs{$set}");

      shell("gzip -c $reclmmf{$set} > $reclmmf{$set}.noembedded.gz");
   }
}


# HERest (embedded reestimation (re-clustered)) 
if ($ERST4) {
   print_time("embedded reestimation (re-clustered)");

   for ($i=1;$i<=$nIte;$i++) {
      print("\n\nIteration $i of Embedded Re-estimation\n");
      shell("$HERest{'ful'} -H $reclmmf{'cmp'} -N $reclmmf{'dur'} -M $model{'cmp'} -R $model{'dur'} $lst{'ful'} $lst{'ful'}");
   }

   # compress reestimated mmfs
   foreach $set (@SET) {
      shell("gzip -c $reclmmf{$set} > $reclmmf{$set}.embedded.gz");
   }
}


# HHEd (making unseen models (1mix))
if ($MKUN1) {
   print_time("making unseen models (1mix)");
   
   foreach $set (@SET) {
      make_edfile_mkunseen($set);
      shell("$HHEd{'trn'} -H $reclmmf{$set} -w $rclammf{$set}.1mix $mku{$set} $lst{'ful'}");
   }
}


# HMGenS (generating speech parameter sequences (1mix))
if ($PGEN1) {
   print_time("generating speech parameter sequences (1mix)");

   $mix = '1mix';
   
   mkdir "${prjdir}/gen/qst${qnum}/ver${ver}/$mix", 0755;
   for ($pgtype=0; $pgtype<=0; $pgtype++) {
      # prepare output directory 
      $dir = "${prjdir}/gen/qst${qnum}/ver${ver}/$mix/$pgtype";
      mkdir $dir, 0755; 
            
      # generate parameter
      shell("$HMGenS -c $pgtype -H $rclammf{'cmp'}.$mix -N $rclammf{'dur'}.$mix -M $dir $tiedlst{'cmp'} $tiedlst{'dur'}");
   }
}


# SPTK (synthesizing waveforms (1mix))
if ($WGEN1) {
   print_time("synthesizing waveforms (1mix)");

   $mix = '1mix';

   mkdir "${prjdir}/gen/qst${qnum}/ver${ver}/$mix", 0755;
   for ($pgtype=0; $pgtype<=0; $pgtype++) {
      gen_wave("${prjdir}/gen/qst${qnum}/ver${ver}/$mix/$pgtype");
   }
}


# HERest (computing log prob on test set (1mix))
if ($LTST1) {
   print_time("computing log prob on test set (1mix)");

   $mix = '1mix';

   if (-s $scp{'tst'}) {
      shell("$HERest{'tst'} -H $rclammf{'cmp'}.$mix -N $rclammf{'dur'}.$mix -M /dev/null -R /dev/null $tiedlst{'cmp'} $tiedlst{'dur'}");
   }
   else {
      print("(skipping since test set is empty)\n\n");
   }
}


# sub routines ============================
sub shell($) {
   my($command) = @_;
   my($exit);

   $exit = system($command);

   if($exit/256 != 0){
      die "Error in $command\n"
   }
}

sub print_time ($) {
   my($message) = @_;
   my($ruler);

   chomp($hostname=`hostname`);
   chomp($date=`date`);

   $message = "Start $message on $hostname at $date";

   $ruler = '';
   for ($i=0; $i<=length($message)+2; $i++) {
      $ruler .= '=';
   }
   
   print "\n$ruler\n";
   print "$message\n";
   print "$ruler\n\n";
}

# sub routine for generating proto-type model
sub make_proto {
   my($i, $j, $k, $s);

   # name of proto type definition file
   $prtfile .= "state-${nState}_stream-$nstream{'total'}";
   foreach $type (@cmp) {
      $prtfile .= "_${type}-$vSize{$type}";
   }
   $prtfile .= ".prt";


   # output prototype definition
   # open proto type definition file 
   open(PROTO,">$prtfile") || die "Cannot open $!";

   # output header 
   # output vector size & feature type
   print PROTO "~o <VecSize> $vSize{'total'} <USER> <DIAGC>";
   
   # output information about multi-space probability distribution (MSD)
   print PROTO "<MSDInfo> $nstream{'total'} ";
   foreach $type (@cmp) {
      for ($s=$strb{$type};$s<=$stre{$type};$s++) {
         print PROTO " $msdi{$type} ";
      }
   }
   
   # output information about stream
   print PROTO "<StreamInfo> $nstream{'total'}";
   foreach $type (@cmp) {
      for ($s=$strb{$type};$s<=$stre{$type};$s++) {
         printf PROTO " %d", $vSize{$type}/$nstream{$type};
      }
   }
   print PROTO "\n";

   # output HMMs
   print  PROTO "<BeginHMM>\n";
   printf PROTO "  <NumStates> %d\n", $nState+2;

   # output HMM states 
   for ($i=2;$i<=$nState+1;$i++) {
      # output state information
      print PROTO "  <State> $i\n";

      # output stream weight
      print PROTO "  <SWeights> $nstream{'total'}";
      foreach $type (@cmp) {
         for ($s=$strb{$type};$s<=$stre{$type};$s++) {
            print PROTO " $strw{$type}";
         }
      }
      print PROTO "\n";

      # output stream information
      foreach $type (@cmp) {
         for ($s=$strb{$type};$s<=$stre{$type};$s++) {
            print  PROTO "  <Stream> $s\n";
            if ($msdi{$type}==0) { # non-MSD stream
               # output mean vector 
               printf PROTO "    <Mean> %d\n", $vSize{$type}/$nstream{$type};
               for ($k=1;$k<=$vSize{$type}/$nstream{$type};$k++) {
                  print PROTO "      " if ($k%10==1); 
                  print PROTO "0.0 ";
                  print PROTO "\n" if ($k%10==0);
               }
               print PROTO "\n" if ($k%10!=1);

               # output covariance matrix (diag)
               printf PROTO "    <Variance> %d\n", $vSize{$type}/$nstream{$type};
               for ($k=1;$k<=$vSize{$type}/$nstream{$type};$k++) {
                  print PROTO "      " if ($k%10==1); 
                  print PROTO "1.0 ";
                  print PROTO "\n" if ($k%10==0);
               }
               print PROTO "\n" if ($k%10!=1);
            }	     
            else { # MSD stream 
               # output MSD
               print  PROTO "  <NumMixes> 2\n";

               # output 1st space (non 0-dimensional space)
               # output space weights
               print  PROTO "  <Mixture> 1 0.5000\n";
               
               # output mean vector 
               printf PROTO "    <Mean> %d\n",$vSize{$type}/$nstream{$type};
               for ($k=1;$k<=$vSize{$type}/$nstream{$type};$k++) {
                  print PROTO "      " if ($k%10==1); 
                  print PROTO "0.0 ";
                  print PROTO "\n" if ($k%10==0);
               }
               print PROTO "\n" if ($k%10!=1);

               # output covariance matrix (diag)
               printf PROTO "    <Variance> %d\n", $vSize{$type}/$nstream{$type};
               for ($k=1;$k<=$vSize{$type}/$nstream{$type};$k++) {
                  print PROTO "      " if ($k%10==1); 
                  print PROTO "1.0 ";
                  print PROTO "\n" if ($k%10==0);
               }
               print PROTO "\n" if ($k%10!=1);

               # output 2nd space (0-dimensional space)
               print PROTO "  <Mixture> 2 0.5000\n";
               print PROTO "    <Mean> 0\n";
               print PROTO "    <Variance> 0\n";
            }
         }
      }
   }

   # output state transition matrix
   printf PROTO "  <TransP> %d\n", $nState+2;
   print  PROTO "    ";
   for ($j=1;$j<=$nState+2;$j++) {
      print PROTO "1.000e+0 " if ($j==2);
      print PROTO "0.000e+0 " if ($j!=2);
   }
   print PROTO "\n";
   print PROTO "    ";
   for ($i=2;$i<=$nState+1;$i++) {
      for ($j=1;$j<=$nState+2;$j++) {
         print PROTO "6.000e-1 " if ($i==$j);
         print PROTO "4.000e-1 " if ($i==$j-1);
         print PROTO "0.000e+0 " if ($i!=$j && $i!=$j-1);
      }
      print PROTO "\n";
      print PROTO "    ";
   }
   for ($j=1;$j<=$nState+2;$j++) {
      print PROTO "0.000e+0 ";
   }
   print PROTO "\n";

   # output footer
   print PROTO "<EndHMM>\n";

   close(PROTO);

   # output variance flooring macro for duration model
   open(VF,">$vfloors{'dur'}") || die "Cannot open $!";
   for ($i=1;$i<=$nState;$i++) {
      print VF "~v varFloor$i\n";
      print VF "<Variance> 1\n";
      print VF " 1.0\n"
   }
   close(VF);
}      

# sub routine for generating config files
sub make_config {
   my($s,$type,@boolstring);
   $boolstring[0] = 'FALSE';
   $boolstring[1] = 'TRUE';

   # config file for model training 
   open(CONF,">$cfg{'trn'}") || die "Cannot open $!";
   print CONF "APPLYVFLOOR = T\n";
   print CONF "NATURALREADORDER = T\n";
   print CONF "NATURALWRITEORDER = T\n";
   print CONF "MINLEAFOCC = $minocc\n";
   print CONF "TREEMERGE = F\n";
   print CONF "VFLOORSCALESTR = \"Vector $nstream{'total'}";
   foreach $type (@cmp) {
      for ($s=$strb{$type}; $s<=$stre{$type}; $s++) {
         print CONF " $vflr{$type}";
      }
   }
   print CONF "\"\n";
   printf CONF "DURVARFLOORPERCENTILE = %f\n", 100*$vflr{'dur'};
   print CONF "APPLYDURVARFLOOR = T\n";
   print CONF "MAXSTDDEVCOEF = $maxdev\n";
   print CONF "MINDUR = $mindur\n";
   close(CONF);

   open(CONF,">$cfg{'tst'}") || die "Cannot open $!";
   print CONF "NATURALREADORDER = T\n";
   print CONF "NATURALWRITEORDER = T\n";
   print CONF "MAXSTDDEVCOEF = $maxdev\n";
   print CONF "MINDUR = $mindur\n";
   print CONF "UPDATEMODE = NONE\n";
   close(CONF);

   # config file for model training (without variance flooring)
   open(CONF,">$cfg{'nvf'}") || die "Cannot open $!";
   print CONF "APPLYVFLOOR = F\n";
   print CONF "DURVARFLOORPERCENTILE = 0.0\n";
   print CONF "APPLYDURVARFLOOR = F\n";
   close(CONF);

   # config file to dump accumulators even in re-estimation mode
   open(CONF,">$cfg{'dump_accs'}") || die "Cannot open $!";
   print CONF "UPDATEMODE = BOTH\n";
   close(CONF);

   # config file for parameter generation
   open(CONF,">$cfg{'syn'}") || die "Cannot open $!";
   print CONF "NATURALREADORDER = T\n";
   print CONF "NATURALWRITEORDER = T\n";
   print CONF "USEALIGN = T\n";
   
   print CONF "PDFSTRSIZE = \"IntVec $nPdfStreams";  # PdfStream structure
   foreach $type (@cmp) {
      print CONF " $nstream{$type}";
   }
   print CONF "\"\n";
   
   print CONF "PDFSTRORDER = \"IntVec $nPdfStreams";  # order of each PdfStream
   foreach $type (@cmp) {
      print CONF " $ordr{$type}";
   }
   print CONF "\"\n";
   
   print CONF "PDFSTREXT = \"StrVec $nPdfStreams";  # filename extension for each PdfStream
   foreach $type (@cmp) {
      print CONF " $type";
   }
   print CONF "\"\n";
   
   print CONF "WINFN = \"";
   foreach $type (@cmp) {
      print CONF "StrVec $nwin{$type} @{$win{$type}} ";  # window coefficients files for each PdfStream
   }
   print CONF "\"\n";
   print CONF "WINDIR = $windir\n";  # directory which stores window coefficients files
   
   print CONF "MAXEMITER = $maxEMiter\n";
   print CONF "EMEPSILON = $EMepsilon\n";
   print CONF "USEGV      = $boolstring[$useGV]\n";
   print CONF "GVMODELMMF = $gvmmf{'cmp'}\n";
   print CONF "GVHMMLIST  = $gvlst{'cmp'}\n";
   print CONF "MAXGVITER  = $maxGViter\n";
   print CONF "GVEPSILON  = $GVepsilon\n";
   print CONF "MINEUCNORM = $minEucNorm\n";
   print CONF "STEPINIT   = $stepInit\n";
   print CONF "STEPINC    = $stepInc\n";
   print CONF "STEPDEC    = $stepDec\n";
   print CONF "HMMWEIGHT  = $hmmWeight\n";
   print CONF "GVWEIGHT   = $gvWeight\n";
   print CONF "OPTKIND    = $optKind\n";
   
   close(CONF);      
}

# sub routine for generating .hed files for decision-tree clustering
sub make_edfile_state($){
   my($set, $final) = @_;
   my(@lines,$i,@nstate);

   $nstate{'cmp'} = $nState;
   $nstate{'dur'} = 1;

   open(QSFILE,"$qs{$set}") || die "Cannot open $!";
   @lines = <QSFILE>;
   close(QSFILE);

   open(EDFILE,">$cxc{$set}") || die "Cannot open $!";
   print EDFILE "// load stats file\n";
   print EDFILE "RO $gam{$set} \"$stats{$set}\"\n";
   print EDFILE "// load accumulator file\n";
   print EDFILE "LA \"$accs{$set}\"\n\n";
   print EDFILE "TR 0\n\n";
   print EDFILE "// questions for decision tree-based context clustering\n";
   print EDFILE @lines;
   print EDFILE "TR 3\n\n";
   print EDFILE "// construct decision trees\n";
   foreach $type (@{$ref{$set}}) {
      if ($final == 1 || $strw{$type}>0.0) {
         for ($i=2;$i<=$nstate{$t2s{$type}}+1;$i++){
            print EDFILE "TB $thr{$type} ${type}_s${i}_ {*.state[${i}].stream[$strb{$type}-$stre{$type}]}\n";
         }
      }
   }
   print EDFILE "\nTR 1\n\n";
   print EDFILE "// output constructed trees\n";
   print EDFILE "ST \"$tre{$set}\"\n";
   close(EDFILE);
}

# sub routine for untying structures
sub make_edfile_untie($){
   my($set) = @_;
   my($type,$i,@nstate);

   $nstate{'cmp'} = $nState;
   $nstate{'dur'} = 1;

   open(EDFILE,">$unt{$set}") || die "Cannot open $!";

   print EDFILE "// untie parameter sharing structure\n";
   foreach $type (@{$ref{$set}}) {
      for($i=2;$i<=$nstate{$set}+1;$i++){
         if ($set eq "dur") {
            print EDFILE "UT {*.state[$i]}\n";
         }
         else {
            if ($strw{$type}>0.0) {
               print EDFILE "UT {*.state[$i].stream[$strb{$type}-$stre{$type}]}\n";
            }
         }
      }
   }

   close(EDFILE);
}

# sub routine to convert statistics file for cmp into one for dur
sub convstats {
   open(IN, "$stats{'cmp'}")  || die "Cannot open $!";
   open(OUT,">$stats{'dur'}") || die "Cannot open $!";
   while(<IN>){
      @LINE = split(' ');
      printf OUT ("%4d %14s %4d %4d\n",$LINE[0],$LINE[1],$LINE[2],$LINE[2]);
   }
   close(IN);
   close(OUT);
}

# sub routine for generating .hed files for making unseen models
sub make_edfile_mkunseen($){
   my($set) = @_;
   my($type);

   open(EDFILE,">$mku{$set}") || die "Cannot open $!";
   print EDFILE "\nTR 2\n\n";
   print EDFILE "// load trees for $set\n";
   print EDFILE "LT \"$tre{$set}\"\n\n";

   print EDFILE "// make unseen model\n";
   print EDFILE "AU \"$lst{'all'}\"\n\n";
   print EDFILE "// make model compact\n";
   print EDFILE "CO \"$tiedlst{$set}\"\n\n";

   close(EDFILE);
}

# sub routine for gv_{mgc,lf0}.pdf -> gv.mmf
sub conv_gvpdf2mmf {
   my($vsize, $stream, $data, $PI, @pdf); 
   $PI = 3.14159265358979;
   $vsize = 0;
   
   open(OUT,">$gvmmf{'cmp'}") || die "cannot open file: $gvmmf{'cmp'}";
 
   # output header
   $nGVstr = @cmp;
   printf OUT "~o\n";
   printf OUT "<STREAMINFO> %d ", $nGVstr;
   foreach $type (@cmp) {
      printf OUT "%d ", $ordr{$type};
      $vsize += $ordr{$type};
   }
   printf OUT "\n<VECSIZE> %d <NULLD><USER><DIAGC>\n", $vsize;
   printf OUT "~h \"gv\"\n";
   printf OUT "<BEGINHMM>\n";
   printf OUT "<NUMSTATES> 3\n";
   printf OUT "<STATE> 2\n";
 
   $stream = 1;
   foreach $type (@cmp) {
      open(IN,$gvpdf{$type}) || die "cannot open file: $gvpdf{$type}";
      @STAT=stat(IN);
      read(IN,$data,$STAT[7]);
      close(IN);

      $n = $STAT[7]/4;
      @pdf = unpack("f$n",$data);

      # output stream index
      printf OUT "<Stream> %d\n", $stream;
      
      # output mean
      printf OUT "<Mean> %d\n", $ordr{$type};
      for ($i=0; $i<$ordr{$type}; $i++) {
          $mean = shift(@pdf);
          printf OUT "%e ", $mean;
      }

      # output variance
      printf OUT "\n<Variance> %d\n", $ordr{$type};
      $gConst = $ordr{$type}*log(2*$PI); 
      for ($i=0; $i<$ordr{$type}; $i++) {
         $var = shift(@pdf);
         printf OUT "%e ",$var;
         $gConst += log($var);
      }
      printf OUT "\n<GConst> %e\n", $gConst;
      $stream++;
   }
 
   # output footer
   print OUT "<TRANSP> 3\n";
   print OUT "0 1 0\n";
   print OUT "0 0 1\n";
   print OUT "0 0 0\n";
   print OUT "<ENDHMM>\n";
   
   close(OUT);
   
   # generate gv list
   open(OUT,">$gvlst{'cmp'}") || die "cannot open file: $gvlst{'cmp'}";
   print OUT "gv\n";
   close(OUT);
}

# sub routine for log f0 -> f0 conversion
sub lf02f0($$) {
   my($base,$gendir) = @_;
   my($t,$T,$data);

   # read log f0 file
   open(IN,"$gendir/${base}.lf0");
   @STAT=stat(IN);
   read(IN,$data,$STAT[7]);
   close(IN);

   # log f0 -> f0 conversion
   $T = $STAT[7]/4;
   @frq = unpack("f$T",$data);
   for ($t=0; $t<$T; $t++) {
      if ($frq[$t] == -1.0e+10) {
         $out[$t] = 0.0;
      } else {
         $out[$t] = exp($frq[$t]);
      }
   }
   $data = pack("f$T",@out);

   # output data
   open(OUT,">$gendir/${base}.f0");
   print OUT $data;
   close(OUT);
   
   return $T;
}

# sub routine for formant emphasis in Mel-cepstral domain
sub postfiltering($$) {
   my($base,$gendir) = @_;
   my($i,$line);

   # output postfiltering weight coefficient 
   $line = "echo 1 1 ";
   for ($i=2; $i<$ordr{'mgc'}; $i++) {
      $line .= "$pf ";
   }
   $line .= "| $X2X +af > $gendir/weight";
   shell($line);

   # calculate auto-correlation of original mcep
   $line = "$FREQT -m ".($ordr{'mgc'}-1)." -a $fw -M $co -A 0 < $gendir/${base}.mgc |"
         . "$C2ACR -m $co -M 0 -l $fl > $gendir/${base}.r0";
   shell($line);
         
   # calculate auto-correlation of postfiltered mcep   
   $line = "$VOPR  -m -n ".($ordr{'mgc'}-1)." < $gendir/${base}.mgc $gendir/weight | "
         . "$FREQT    -m ".($ordr{'mgc'}-1)." -a $fw -M $co -A 0 | "
         . "$C2ACR -m $co -M 0 -l $fl > $gendir/${base}.p_r0";
   shell($line);

   # calculate MLSA coefficients from postfiltered mcep 
   $line = "$VOPR -m -n ".($ordr{'mgc'}-1)." < $gendir/${base}.mgc $gendir/weight | "
         . "$MC2B    -m ".($ordr{'mgc'}-1)." -a $fw | "
         . "$BCP     -n ".($ordr{'mgc'}-1)." -s 0 -e 0 > $gendir/${base}.b0";
   shell($line);
   
   # calculate 0.5 * log(acr_orig/acr_post)) and add it to 0th MLSA coefficient     
   $line = "$VOPR -d < $gendir/${base}.r0 $gendir/${base}.p_r0 | "
         . "$SOPR -LN -d 2 | "
         . "$VOPR -a $gendir/${base}.b0 > $gendir/${base}.p_b0";
   shell($line);
   
   # generate postfiltered mcep
   $line = "$VOPR  -m -n ".($ordr{'mgc'}-1)." < $gendir/${base}.mgc $gendir/weight | "
         . "$MC2B     -m ".($ordr{'mgc'}-1)." -a $fw | "
         . "$BCP      -n ".($ordr{'mgc'}-1)." -s 1 -e ".($ordr{'mgc'}-1)." | "
         . "$MERGE    -n ".($ordr{'mgc'}-2)." -s 0 -N 0 $gendir/${base}.p_b0 | "
         . "$B2MC     -m ".($ordr{'mgc'}-1)." -a $fw > $gendir/${base}.p_mgc";
   shell($line);
}

# sub routine for speech synthesis from log f0 and Mel-cepstral coefficients 
sub gen_wave($) {
   my($gendir) = @_;
   my($line,@FILE,$num,$period,$file,$base,$T,$endian);

   $line   = `ls $gendir/*.mgc`;
   @FILE   = split('\n',$line);
   $num    = @FILE;
   $lgopt = "-l" if ($lg);

   print "Processing directory $gendir:\n";
   
   # synthesize a waveform STRAIGHT
   open(SYN, ">$datdir/scripts/synthesis.m") || die "Cannot open $!";
   printf SYN "path(path,'%s');\n", ${STRAIGHT};
   printf SYN "prm.spectralUpdateInterval = %f;\n\n", 1000.0*$fs/$sr;
   if ($bs==0) {
      $endian = "ieee-le";
   }
   else {
      $endian = "ieee-be";
   }

   foreach $file (@FILE) {
      $base = `basename $file .mgc`;
      chomp($base);
      if ( -s $file && -s "$gendir/$base.lf0" ) {
         print " Converting $base.mgc, $base.lf0, and $base.bap to STRAIGHT params...";
         
         # convert log F0 to pitch
         $T = lf02f0($base,$gendir);
         
         if ($ul) {
            # MGC-LSPs -> MGC coefficients
            $line = "$LSPCHECK -m ".($ordr{'mgc'}-1)." -s ".($sr/1000)." -r $file | "
                  . "$LSP2LPC  -m ".($ordr{'mgc'}-1)." -s ".($sr/1000)." $lgopt | "
                  . "$MGC2MGC  -m ".($ordr{'mgc'}-1)." -a $fw -g $gm -n -u -M ".($ordr{'mgc'}-1)." -A $fw -G $gm "
                  . " > $gendir/$base.c_mgc";
            shell($line);
            
            $mgc = "$gendir/$base.c_mgc";
         }
         else { 
            # apply postfiltering
            if ($gm==0 && $pf!=1.0 && $useGV==0) {
               postfiltering($base,$gendir);
               $mgc = "$gendir/$base.p_mgc";
            }
            else {
               $mgc = $file;
            }
         }
         
         # convert mgc to spectra
         shell("$MGC2SP -a $fw -g $gm -m ".($ordr{'mgc'}-1)." -l 1024 -o 2 $mgc > $gendir/$base.sp");

         # convert band-aperiodicity to aperiodicity
         $bap = "$gendir/$base.bap";
         shell("$BCP +f -l 5 -L 1 -s 0 -e 0 -S 0 $bap | ${DFS} -b 1 -1 | ${INTERPOLATE} -p  64 | ${DFS} -a 1 -1 > $gendir/$base.ap1");
         shell("$BCP +f -l 5 -L 1 -s 1 -e 1 -S 0 $bap | ${DFS} -b 1 -1 | ${INTERPOLATE} -p  64 | ${DFS} -a 1 -1 > $gendir/$base.ap2");
         shell("$BCP +f -l 5 -L 1 -s 2 -e 2 -S 0 $bap | ${DFS} -b 1 -1 | ${INTERPOLATE} -p 128 | ${DFS} -a 1 -1 > $gendir/$base.ap3");
         shell("$BCP +f -l 5 -L 1 -s 3 -e 3 -S 0 $bap | ${DFS} -b 1 -1 | ${INTERPOLATE} -p 128 | ${DFS} -a 1 -1 > $gendir/$base.ap4");
         shell("$BCP +f -l 5 -L 1 -s 4 -e 4 -S 0 $bap | ${DFS} -b 1 -1 | ${INTERPOLATE} -p 129 | ${DFS} -a 1 -1 > $gendir/$base.ap5");

         $line = "$MERGE -s   0 -l  64 -L  64 $gendir/$base.ap1 $gendir/$base.ap2 | "
               . "$MERGE -s 128 -l 128 -L 128 $gendir/$base.ap3 | "
               . "$MERGE -s 256 -l 256 -L 128 $gendir/$base.ap4 | "
               . "$MERGE -s 384 -l 384 -L 129 $gendir/$base.ap5 > $gendir/$base.ap";
         shell($line); 
         
         printf SYN "fprintf(1,'Synthesizing %s');\n",   "$gendir/$base.wav";
         printf SYN "fid1 = fopen('%s','r','%s');\n", "$gendir/$base.sp", $endian;
         printf SYN "fid2 = fopen('%s','r','%s');\n", "$gendir/$base.ap", $endian;
         printf SYN "fid3 = fopen('%s','r','%s');\n", "$gendir/$base.f0", $endian;

         printf SYN "sp = fread(fid1,[%d, %d],'float');\n", 513, $T;
         printf SYN "ap = fread(fid2,[%d, %d],'float');\n", 513, $T;
         printf SYN "f0 = fread(fid3,[%d, %d],'float');\n", 1,   $T;

         print  SYN  "fclose(fid1);\n";
         print  SYN  "fclose(fid2);\n";
         print  SYN  "fclose(fid3);\n";

         printf SYN "[sy] = exstraightsynth(f0,sp,ap,%d,prm);\n", $sr;
         printf SYN "wavwrite( sy/max(abs(sy))*0.95, %d, '%s');\n\n",  $sr, "$gendir/$base.wav";
                  
         print "done\n";
      }
   }
   printf SYN "quit;\n";
   close(SYN);
   
   print "Synthesizing waveform from STRAIGHT parameters...\n";
   shell("$MATLAB < $datdir/scripts/synthesis.m");
   print "done\n";

   # clean-up temporary files
   foreach $file (@FILE) {
      $base = `basename $file .mgc`;
      chomp($base);
      shell("rm -f $gendir/$base.sp $gendir/$base.f0 $gendir/$base.ap $gendir/$base.ap\[12345\]");
   }
}

##################################################################################################

