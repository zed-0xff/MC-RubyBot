package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;

import java.util.List;

import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

import net.minecraft.command.CommandSource;
import net.minecraft.client.network.ClientCommandSource;
import net.minecraft.client.gui.screen.CommandSuggestor;
import net.minecraft.client.gui.widget.TextFieldWidget;

import com.mojang.brigadier.ParseResults;
import com.mojang.brigadier.context.StringRange;
import com.mojang.brigadier.suggestion.Suggestion;
import com.mojang.brigadier.suggestion.Suggestions;
import com.mojang.brigadier.context.CommandContext;

import java.util.concurrent.CompletableFuture;
import java.util.Collection;
import java.util.ArrayList;

@Mixin(CommandSuggestor.class)
public class MixinCommandSuggestions {

//    @Shadow
//    @Final
//    TextFieldWidget textField;
//
//    @Shadow
//    private CompletableFuture<Suggestions> pendingSuggestions;
//
//    @Inject( method = "show()V", at = @At("HEAD"))
//    private void foo(CallbackInfo ci) {
//		int offset = this.textField.getText().endsWith(" ")
//			? this.textField.getCursor()
//			: this.textField.getText().lastIndexOf(" ") + 1; // If there is no space this is still 0 haha yes
//
//        String str = "/xxx";
//		List<Suggestion> suggestionList = new ArrayList<Suggestion>();
//		suggestionList.add(new Suggestion(StringRange.between(offset, offset + str.length()), str));
//
//		Suggestions suggestions = new Suggestions(
//				StringRange.between(offset, offset + suggestionList.stream().mapToInt(s -> s.getText().length()).max().orElse(0)),
//				suggestionList);
//
//		this.pendingSuggestions = new CompletableFuture<>();
//		this.pendingSuggestions.complete(suggestions);
//    }

//    @Inject( method = "parse:Lcom/mojang/brigadier/ParseResults;", at = @At("RETURN"))
//    private void foo2(CallbackInfoReturnable<ParseResults<CommandSource>> cir) {
//    }
//
//    @Inject( method = "sortSuggestions(Lcom/mojang/brigadier/suggestion/Suggestions;)Ljava/util/List;", at = @At("RETURN"))
//    private void bar(Suggestions suggestions, CallbackInfoReturnable<List<Suggestion>> cir) {
//        String prefix = this.textField.getText();
//
//		int offset = 1;
//
//		List<String> commands = new ArrayList<String>();
//        commands.add("stop");
//        commands.add("loadsomething");
//        for( String cmd : commands ) {
//            if( cmd.startsWith(prefix.substring(1)) ) {
//                cir.getReturnValue().add(new Suggestion(StringRange.between(offset, offset + cmd.length()), cmd));
//                for ( Suggestion s : cir.getReturnValue() ){
//                    ExampleMod.LOGGER.info("[d] " + s.getText() + " " + s.getRange() + " " + s.getTooltip());
//                }
//            }
//        }
//    }


//    @Inject( method = "getEntitySuggestions()Ljava/util/Collection;", at = @At("HEAD"))
//    private void preUpdateSuggestion(CallbackInfoReturnable<Collection<String>> cir) {
//        if ( ExampleMod.LOGGER != null ) {
//            ExampleMod.LOGGER.info("[d] getEntitySuggestions");
//        }
//    }
//
//    @Inject( method = "getCompletions(Lcom/mojang/brigadier/context/CommandContext;)Ljava/util/concurrent/CompletableFuture;", at = @At("HEAD"))
//    private void bar(CommandContext<?> context, CallbackInfoReturnable<CompletableFuture<Suggestions>> cir) {
//        if ( ExampleMod.LOGGER != null ) {
//            ExampleMod.LOGGER.info("[d] getCompletions");
//        }
//    }

//    @Shadow
//    @Final
//    private List<String> commandUsage;
//
//    @Inject(
//        method = "updateCommandInfo",
//        at = @At("HEAD"),
//        cancellable = true
//    )
//    private void preUpdateSuggestion(CallbackInfo ci) {
//        // Anything that is present in the input text before the cursor position
////        String prefix = this.input.getValue().substring(0, Math.min(this.input.getValue().length(), this.input.getCursorPosition()));
////        TabCompleteEvent event = new TabCompleteEvent(prefix);
//      commandUsage.append("no shit!");
//    }
}
