package net.fabricmc.example.utils;
import net.fabricmc.example.ExampleMod;

import net.fabricmc.example.mixin.*;

import net.minecraft.block.Block;
import net.minecraft.block.Blocks;
import net.minecraft.client.MinecraftClient;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.Hand;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.hit.HitResult;
import net.minecraft.util.math.Direction;

import net.minecraft.network.packet.c2s.play.PlayerActionC2SPacket;
import net.minecraft.network.packet.c2s.play.PlayerActionC2SPacket.Action;

public class BlockBreakHelper {
    private static boolean g_isBreaking = false;
    private static boolean g_oneShot = false;
    private static BlockPos g_blockPos = null;
    private static Block g_block = null;
    private static int lastTick = 0;

    public static boolean isBreakingBlock() {
        return g_isBreaking;
    }

    public static boolean startBreakingBlock(BlockHitResult blockHit, MinecraftClient mc) {
        return startBreakingBlock(blockHit, mc, false);
    }

    public static boolean startBreakingBlock(BlockHitResult blockHit, MinecraftClient mc, boolean oneShot) {
        if ( blockHit == null )
            return false;

        return startBreakingBlock(blockHit.getBlockPos(), blockHit.getSide(), mc, oneShot);
    }

    public static boolean startBreakingBlock(BlockPos blockPos, Direction side, MinecraftClient mc, boolean oneShot) {
        Block block = mc.world.getBlockState(blockPos).getBlock();

        ExampleMod.LOGGER.info("[d] startBreakingBlock g_isBreaking=" + g_isBreaking + ", block=" + block);

        // refuse to break lowest sugarcane row
        if ( block instanceof net.minecraft.block.SugarCaneBlock ) {
            Block bottomBlock = mc.world.getBlockState(new BlockPos(blockPos.getX(), blockPos.getY()-1, blockPos.getZ())).getBlock();
            if ( !(bottomBlock instanceof net.minecraft.block.SugarCaneBlock) ){
                return false;
            }
        }

//        if ( g_isBreaking ) {
//            if ( g_blockPos.equals( blockPos ) && block.equals(g_block) ){
//                // already breaking it
//                return true;
//            }
//            stopBreakingBlock(mc);
//        }

        g_block    = block;
        g_blockPos = blockPos;
        g_oneShot  = oneShot;

        ClientPlayerInteractionManagerAccessor mca = (ClientPlayerInteractionManagerAccessor)mc.interactionManager;

        if( g_oneShot ){
            // from ClientPlayerInteractionManager sources
            // works with detached camera!
            // upd: actually this code path is not needed anymore bc
            // it was enough to enable CameraUtils.shouldPreventPlayerInputs option in tweakeroo :]
            mca.invokeSendSequencedPacket(mc.world, (sequence) -> {
                mc.interactionManager.breakBlock(g_blockPos);
                return new PlayerActionC2SPacket(Action.START_DESTROY_BLOCK, g_blockPos, side, sequence);
            });
            mc.player.swingHand(Hand.MAIN_HAND);
            return true;
        } else {
            // logic copied from baritone
            mca.invokeSyncSelectedSlot();
            g_isBreaking = mc.interactionManager.attackBlock( g_blockPos, side );
            // trick it, so it does not track the mouse and stuff
            mca.setBreakingBlock(false);
            mc.player.swingHand(Hand.MAIN_HAND);
            return g_isBreaking;
        }
    }

    public static void stopBreakingBlock(MinecraftClient mc) {
        ExampleMod.LOGGER.info("[d] stopBreakingBlock g_isBreaking=" + g_isBreaking);
        if ( g_isBreaking ) {
            g_block      = null;
            g_blockPos   = null;
            g_isBreaking = false;

            if ( g_oneShot ) {
                // don't send ABORT_DESTROY_BLOCK
                g_oneShot = false;
            } else {
                ClientPlayerInteractionManagerAccessor mca = (ClientPlayerInteractionManagerAccessor)mc.interactionManager;

                // otherwise it would not send ABORT_DESTROY_BLOCK
                mca.setBreakingBlock(true);
                mc.interactionManager.cancelBlockBreaking();
            }
        }
    }

    public static void tick(MinecraftClient mc) {
        if ( lastTick == ExampleMod.tick ) return;
        lastTick = ExampleMod.tick;

        if ( g_isBreaking ) {
            HitResult target = RayTraceUtils.crosshairTargetOrRaytrace(mc);
            if ( !(target instanceof BlockHitResult) ) {
                stopBreakingBlock(mc);
                return;
            }
            BlockHitResult blockHit = (BlockHitResult)target;
            if ( !g_blockPos.equals( blockHit.getBlockPos() ) ){
                stopBreakingBlock(mc);
                return;
            }

            Block newBlock = mc.world.getBlockState(g_blockPos).getBlock();
            if ( !g_block.equals(newBlock) ){
                ExampleMod.LOGGER.info("[d] " + g_blockPos.toString() + ": " + g_block.toString() + " -> " + newBlock.toString());
                if ( newBlock == Blocks.BEDROCK ){
                    stopBreakingBlock(mc);
                } else {
                    startBreakingBlock(blockHit, mc);
                }
                return;
            }

            if ( mc.interactionManager.updateBlockBreakingProgress( g_blockPos, blockHit.getSide() )) {
                mc.player.swingHand(Hand.MAIN_HAND);
            }
        }
    }
}
