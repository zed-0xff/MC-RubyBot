package net.fabricmc.example.utils;

import net.fabricmc.example.mixin.*;

import net.minecraft.client.MinecraftClient;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.Hand;

public class BlockBreakHelper {
    private static boolean isBreaking = false;

    public static boolean startBreakingBlock(BlockHitResult blockHit, MinecraftClient mc) {
        // logic copied from baritone
        ClientPlayerInteractionManagerAccessor mca = (ClientPlayerInteractionManagerAccessor)mc.interactionManager;
        mca.invokeSyncSelectedSlot();
        isBreaking = mc.interactionManager.attackBlock( blockHit.getBlockPos(), blockHit.getSide() );
        // trick it, so it does not track the mouse and stuff
        mca.setBreakingBlock(false);
        return isBreaking;
    }

    public static void stopBreakingBlock(MinecraftClient mc) {
        if ( isBreaking ) {
            isBreaking = false;
            ClientPlayerInteractionManagerAccessor mca = (ClientPlayerInteractionManagerAccessor)mc.interactionManager;

            // otherwise it would not send ABORT_DESTROY_BLOCK
            mca.setBreakingBlock(true);
            mc.interactionManager.cancelBlockBreaking();
        }
    }

    public static void tick(MinecraftClient mc) {
        if ( isBreaking ) {
            mc.player.swingHand(Hand.MAIN_HAND);
        }
    }
}
